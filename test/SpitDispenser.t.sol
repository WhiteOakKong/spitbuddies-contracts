// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { SpitDispenser } from "../src/SpitDispenser.sol";
import { MockSpit } from "./Mocks/MockSpit.sol";

contract SpitDispenserTest is PRBTest, StdCheats {
    SpitDispenser internal spitDispenser;
    MockSpit internal spit;

    uint256 fork;

    address internal nonOwner = makeAddr("nonOwner");
    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");

    event SpitRateChanged(uint256 newRate);
    event SpitWithdrawn(address indexed recipient, uint256 amount);
    event SpitAddressChanged(address indexed newAddress);
    event SpitClaimed(address indexed user, uint256 amount);

    function setUp() public virtual {
        address _fxChild = makeAddr("fxChild");
        address _fxRootTunnel = makeAddr("fxRootTunnel");
        spitDispenser = new SpitDispenser(_fxChild, _fxRootTunnel);
        spit = new MockSpit();
        spitDispenser.updateSpitAddress(address(spit));
        deal(address(spit), address(spitDispenser), 100 ether);
    }

    function test__processMessageFromRoot_stake1() public {
        vm.startPrank(spitDispenser.fxChild());
        spitDispenser.processMessageFromRoot(1, spitDispenser.fxRootTunnel(), abi.encode(user1, 1, true));
        vm.stopPrank();
        assertEq(spitDispenser.stakedBalance(user1), 1);
    }

    function test__processMessageFromRoot_unstake1() public {
        vm.startPrank(spitDispenser.fxChild());
        spitDispenser.processMessageFromRoot(1, spitDispenser.fxRootTunnel(), abi.encode(user1, 1, true));
        assertEq(spitDispenser.stakedBalance(user1), 1);
        spitDispenser.processMessageFromRoot(1, spitDispenser.fxRootTunnel(), abi.encode(user1, 1, false));
        vm.stopPrank();
        assertEq(spitDispenser.stakedBalance(user1), 0);
    }

    function test_setSpitRate_fail_nonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        spitDispenser.setSpitRate(1 ether);
        vm.stopPrank();
    }

    function test_setSpitRate_success_owner() public {
        spitDispenser.setSpitRate(1 ether);
        assertEq(spitDispenser.spitRate(), 1 ether);
    }

    function test_withdrawSpit_success_owner() public {
        uint256 initBal = spit.balanceOf(address(this));
        spitDispenser.withdrawSpit(address(this), 100 ether);

        assertEq(spit.balanceOf(address(this)), initBal + 100 ether);
        assertEq(spit.balanceOf(address(spitDispenser)), 0);
    }

    function test_withdrawSpit_fail_nonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        spitDispenser.withdrawSpit(address(this), 100 ether);
        vm.stopPrank();
    }

    function test_updateSpitAddress_success() public {
        address newSpit = makeAddr("newSpit");
        spitDispenser.updateSpitAddress(newSpit);
        assertEq(address(spitDispenser.spit()), newSpit);
    }

    function test_updateSpitAddress_fail_nonOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        spitDispenser.updateSpitAddress(address(spit));
        vm.stopPrank();
    }

    function test_updateFxRootTunnel_success() public {
        address newFxRootTunnel = makeAddr("newFxRootTunnel");
        spitDispenser.updateFxRootTunnel(newFxRootTunnel);
        assertEq(spitDispenser.fxRootTunnel(), newFxRootTunnel);
    }

    function test_updateFxRootTunnel_fail_nonOwner() public {
        address newFxRootTunnel = makeAddr("newFxRootTunnel");
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        spitDispenser.updateFxRootTunnel(newFxRootTunnel);
        vm.stopPrank();
    }

    function test_collectSpit_success() public {
        vm.startPrank(spitDispenser.fxChild());
        spitDispenser.processMessageFromRoot(1, spitDispenser.fxRootTunnel(), abi.encode(user1, 1, true));

        vm.stopPrank();

        vm.warp(spitDispenser.lastUpdated(user1) + 86_400);

        uint256 _rewardsPerSecond = 15_000_000_000_000_000_000 / uint256(86_400);
        uint256 expectedReward = _rewardsPerSecond * (block.timestamp - spitDispenser.lastUpdated(user1));
        assertEq(spitDispenser.getUserAccruedRewards(user1), expectedReward);
        vm.startPrank(user1);
        spitDispenser.collectSpit();
        vm.stopPrank();
        assertEq(spitDispenser.getUserAccruedRewards(user1), 0);
        assertEq(spit.balanceOf(user1), expectedReward);
    }
}
