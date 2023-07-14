// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { JiraCentral } from "../src/JiraCentral.sol";

contract JiraCentralTest is PRBTest, StdCheats {
    JiraCentral internal jiraCentral;

    address internal approvedUser = makeAddr("approvedUser");
    address internal unapprovedUser = makeAddr("unapprovedUser");

    event currentRate(address user, uint256 rate);

    function setUp() public virtual {
        jiraCentral = new JiraCentral();
    }

    function test__increaseGeneration_success_approved() public {
        jiraCentral.setApproved(approvedUser, true);
        vm.startPrank(approvedUser);
        vm.expectEmit(false, false, false, true);
        emit currentRate(approvedUser, 100);
        jiraCentral._increaseGeneration(approvedUser, 100);
        assertEq(jiraCentral.userData(approvedUser), 100);
    }

    function test__increaseGeneration_fail_notApproved() public {
        vm.startPrank(unapprovedUser);
        vm.expectRevert("Contract not approved.");
        jiraCentral._increaseGeneration(unapprovedUser, 100);
        assertEq(jiraCentral.userData(unapprovedUser), 0);
    }

    function test__decreaseGeneration_fail_notApproved() public {
        vm.startPrank(unapprovedUser);
        vm.expectRevert("Contract not approved.");
        jiraCentral._decreaseGeneration(unapprovedUser, 100);
        assertEq(jiraCentral.userData(unapprovedUser), 0);
    }

    function test__decreaseGeneration_fail_underflow() public {
        jiraCentral.setApproved(approvedUser, true);
        vm.startPrank(approvedUser);
        //"Arithmetic over/underflow"
        vm.expectRevert();
        jiraCentral._decreaseGeneration(approvedUser, 100);
        assertEq(jiraCentral.userData(approvedUser), 0);
    }

    function test__decreaseGeneration_success_approvedUser() public {
        jiraCentral.setApproved(approvedUser, true);
        vm.startPrank(approvedUser);
        jiraCentral._increaseGeneration(approvedUser, 100);
        vm.expectEmit(false, false, false, true);
        emit currentRate(approvedUser, 0);
        jiraCentral._decreaseGeneration(approvedUser, 100);
        assertEq(jiraCentral.userData(approvedUser), 0);
    }

    function test_setApproved_success_ownerSetTrue() public {
        jiraCentral.setApproved(approvedUser, true);
        assertEq(jiraCentral.approvedContracts(approvedUser), true);
    }

    function test_setApproved_success_ownerSetFalse() public {
        jiraCentral.setApproved(approvedUser, true);
        assertEq(jiraCentral.approvedContracts(approvedUser), true);
        jiraCentral.setApproved(approvedUser, false);
        assertEq(jiraCentral.approvedContracts(approvedUser), false);
    }

    function test_setApproved_fail_notOwner() public {
        vm.startPrank(unapprovedUser);
        vm.expectRevert("Ownable: caller is not the owner");
        jiraCentral.setApproved(unapprovedUser, true);
        assertEq(jiraCentral.approvedContracts(unapprovedUser), false);
    }

    function test_fuzz__decreaseGeneration_handleUnderflow(uint256 increaseValue, uint256 decreaseValue) public {
        jiraCentral.setApproved(approvedUser, true);
        vm.startPrank(approvedUser);
        vm.expectEmit(true, true, true, true);
        emit currentRate(approvedUser, increaseValue);
        jiraCentral._increaseGeneration(approvedUser, increaseValue);
        if (decreaseValue > increaseValue) {
            //"Arithmetic over/underflow"
            vm.expectRevert();
            jiraCentral._decreaseGeneration(approvedUser, decreaseValue);
        } else {
            vm.expectEmit(false, false, false, true);
            emit currentRate(approvedUser, increaseValue - decreaseValue);
            jiraCentral._decreaseGeneration(approvedUser, decreaseValue);
            assertEq(jiraCentral.userData(approvedUser), increaseValue - decreaseValue);
        }
    }
}
