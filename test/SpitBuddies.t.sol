// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { SpitBuddies } from "../src/SpitBuddies.sol";

contract SpitBuddiesTest is PRBTest, StdCheats {
    SpitBuddies internal spitBuddies;

    address internal nonOwner = makeAddr("nonOwner");

    event SpitYardChanged(address indexed _newSpitYard);
    event BaseURIChanged(string _newBaseURI);
    event URIExtensionChanged(string _newURIExtension);

    function setUp() public virtual {
        spitBuddies = new SpitBuddies();
    }

    function test_batchMint_success() public {
        address[] memory mintAddresses = new address[](200);
        for (uint256 i = 0; i < 200; i++) {
            mintAddresses[i] = vm.addr(i + 1);
        }
        spitBuddies.batchMint(mintAddresses);
        for (uint256 i = 0; i < 200; i++) {
            assertEq(spitBuddies.ownerOf(i + 1), mintAddresses[i]);
        }
    }

    function test_batchMint_fail_lessThanMaxSupply() public {
        address[] memory mintAddresses = new address[](199);
        for (uint256 i = 0; i < 199; i++) {
            mintAddresses[i] = vm.addr(i + 1);
        }
        vm.expectRevert("Incorrect Array Length");
        spitBuddies.batchMint(mintAddresses);
    }

    function test_batchMint_fail_NotOwner() public {
        address[] memory mintAddresses = new address[](200);
        for (uint256 i = 0; i < 200; i++) {
            mintAddresses[i] = vm.addr(i + 1);
        }
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        spitBuddies.batchMint(mintAddresses);
    }

    function test_batchMint_fail_CallTwice() public {
        address[] memory mintAddresses = new address[](200);
        for (uint256 i = 0; i < 200; i++) {
            mintAddresses[i] = vm.addr(i + 1);
        }
        spitBuddies.batchMint(mintAddresses);
        vm.expectRevert("Already Minted");
        spitBuddies.batchMint(mintAddresses);
    }

    function test_setBaseURI_success() public {
        vm.expectEmit(false, false, false, true);
        emit BaseURIChanged("test");
        spitBuddies.setBaseURI("test");
        assertEq(spitBuddies.baseURI(), "test");
    }

    function test_setBaseURI_fail_NotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        spitBuddies.setBaseURI("test");
    }

    function test_setURIExtension_success() public {
        vm.expectEmit(false, false, false, true);
        emit URIExtensionChanged("test");
        spitBuddies.setURIExtension("test");
        assertEq(spitBuddies.URIExtension(), "test");
    }

    function test_setURIExtension_fail_NotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        spitBuddies.setURIExtension("test");
    }

    function test_setSpitYard_success() public {
        vm.expectEmit(false, false, false, true);
        emit SpitYardChanged(vm.addr(1));
        spitBuddies.setSpitYard(vm.addr(1));
        assertEq(spitBuddies.spitYard(), vm.addr(1));
    }

    function test_setSpitYard_fail_NotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        spitBuddies.setSpitYard(vm.addr(1));
    }

    function test_setSpityard_fail_ZeroAddress() public {
        vm.expectRevert("Invalid address");
        spitBuddies.setSpitYard(address(0));
    }

    function test_burnTestToken_success() public {
        spitBuddies.burnTestToken();
        assertEq(spitBuddies.totalSupply(), 0);
    }

    function test_burnTestToken_fail_NotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        spitBuddies.burnTestToken();
    }

    function test_isApprovedForAll_spitYard_true() public {
        spitBuddies.setSpitYard(vm.addr(1));
        assertEq(spitBuddies.isApprovedForAll(address(this), vm.addr(1)), true);
    }

    function test_isApprovedForAll_spitYardTryForceFalse_true() public {
        spitBuddies.setSpitYard(vm.addr(1));
        spitBuddies.setApprovalForAll(vm.addr(1), false);
        assertEq(spitBuddies.isApprovedForAll(address(this), vm.addr(1)), true);
    }

    function test_isApprovedForAll_regular_false() public {
        assertEq(spitBuddies.isApprovedForAll(address(this), vm.addr(1)), false);
    }

    function test_isApprovedForAll_regular_true() public {
        spitBuddies.setApprovalForAll(vm.addr(100), true);
        assertEq(spitBuddies.isApprovedForAll(address(this), vm.addr(100)), true);
    }

    function test_tokenURI_fail_invalidToken() public {
        spitBuddies.setBaseURI("https://test.com/");
        spitBuddies.setURIExtension(".json");
        vm.expectRevert("Token does not exist.");
        spitBuddies.tokenURI(1);
    }

    function test_tokenURI_success() public {
        spitBuddies.setBaseURI("https://test.com/");
        spitBuddies.setURIExtension(".json");
        assertEq(spitBuddies.tokenURI(0), "https://test.com/0.json");
    }
}
