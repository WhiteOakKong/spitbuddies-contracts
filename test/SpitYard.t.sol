// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { SpitYard } from "../src/SpitYard.sol";
import { SpitBuddies } from "../src/SpitBuddies.sol";
import { JiraCentral } from "../src/JiraCentral.sol";
import { FxRoot } from "@fxportal/contracts/FxRoot.sol";

contract SpitYardTest is PRBTest, StdCheats {
    SpitYard internal spitYard;
    SpitBuddies internal spitBuddies;
    JiraCentral internal jiraCentral;

    address internal nonOwner = makeAddr("nonOwner");
    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");

    uint256 public fork;
    uint256 public BLOCK_NUMBER = 17_687_103;

    event JiraCentralChanged(address indexed _newJiraCentral);
    event SpitBuddiesChanged(address indexed _newSpitBuddies);
    event SpitBuddiesStaked(address indexed _user, uint256[] _tokenIds);
    event SpitBuddiesUnstaked(address indexed _user, uint256[] _tokenIds);
    event StakingPaused(bool status);

    function setUp() public virtual {
        fork = vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);
        address _cm = 0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287;
        FxRoot _fxRoot = FxRoot(0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2);
        spitBuddies = new SpitBuddies();
        jiraCentral = new JiraCentral();

        spitYard = new SpitYard(address(_cm), address(_fxRoot), address(spitBuddies));
        spitBuddies.setSpitYard(address(spitYard));
        jiraCentral.setApproved(address(spitYard), true);
        spitYard.setJiraCentral(address(jiraCentral));

        address[] memory mintAddresses = new address[](200);
        for (uint256 i = 0; i < 200; i++) {
            mintAddresses[i] = user1;
        }

        spitBuddies.batchMint(mintAddresses);
    }

    function test_stake_success_stake1() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user1);

        spitYard.stake(tokenIds);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 1);
        assertEq(userStake[0], 1);
    }

    function test_stake_success_stake2() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        vm.startPrank(user1);

        spitYard.stake(tokenIds);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 2);
        assertEq(userStake[0], 1);
        assertEq(userStake[1], 2);
    }

    function test_stake_success_stake50() public {
        uint256[] memory tokenIds = new uint256[](50);
        for (uint256 i = 0; i < 50; i++) {
            tokenIds[i] = i + 1;
        }

        vm.startPrank(user1);

        spitYard.stake(tokenIds);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 50);
        for (uint256 i = 0; i < 50; i++) {
            assertEq(userStake[i], i + 1);
        }
    }

    function test_stake_fail_paused() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        spitYard.setStakingPaused(true);

        vm.startPrank(user1);

        vm.expectRevert("Staking is currently paused.");
        spitYard.stake(tokenIds);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 0);
    }

    function test_stake_fail_notOwnerOfToken() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user2);

        vm.expectRevert(bytes4(keccak256("TransferFromIncorrectOwner()")));
        spitYard.stake(tokenIds);

        uint256[] memory userStake = spitYard.getUserStake(user2);

        assertEq(userStake.length, 0);
    }

    function test_stake_fail_alreadyStaked() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user1);

        spitYard.stake(tokenIds);

        vm.expectRevert(bytes4(keccak256("TransferFromIncorrectOwner()")));
        spitYard.stake(tokenIds);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 1);
        assertEq(userStake[0], 1);
    }

    function test_unstake_success_unstake1of1() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user1);

        spitYard.stake(tokenIds);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 1);
        assertEq(userStake[0], 1);

        spitYard.unstake(tokenIds);

        userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 0);
    }

    function test_unstake_success_unstake1of2() public {
        uint256[] memory tokenIdsStake = new uint256[](2);
        tokenIdsStake[0] = 1;
        tokenIdsStake[1] = 2;

        uint256[] memory tokenIdsUnstake = new uint256[](1);
        tokenIdsUnstake[0] = 1;

        vm.startPrank(user1);

        spitYard.stake(tokenIdsStake);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 2);
        assertEq(userStake[0], 1);
        assertEq(userStake[1], 2);

        spitYard.unstake(tokenIdsUnstake);

        userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 1);
    }

    function test_unstake_success_unstake25of50() public {
        uint256[] memory tokenIdsStake = new uint256[](50);
        for (uint256 i = 0; i < 50; i++) {
            tokenIdsStake[i] = i + 1;
        }

        uint256[] memory tokenIdsUnstake = new uint256[](25);
        for (uint256 i = 0; i < 25; i++) {
            tokenIdsUnstake[i] = i + 1;
        }

        vm.startPrank(user1);

        spitYard.stake(tokenIdsStake);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 50);
        for (uint256 i = 0; i < 50; i++) {
            assertEq(userStake[i], i + 1);
        }

        spitYard.unstake(tokenIdsUnstake);

        userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 25);
        for (uint256 i = 0; i < 25; i++) {
            assertEq(userStake[i], 50 - i);
        }
    }

    function test_unstake_fail_paused() public {
        uint256[] memory tokenIdsUnstake = new uint256[](1);
        tokenIdsUnstake[0] = 1;

        spitYard.setStakingPaused(true);

        vm.startPrank(user1);

        vm.expectRevert("Staking is currently paused.");
        spitYard.unstake(tokenIdsUnstake);
    }

    function test_unstake_fail_notStaker() public {
        uint256[] memory tokenIdsStake = new uint256[](1);
        tokenIdsStake[0] = 1;

        uint256[] memory tokenIdsUnstake = new uint256[](1);
        tokenIdsUnstake[0] = 1;

        vm.startPrank(user1);

        spitYard.stake(tokenIdsStake);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 1);
        assertEq(userStake[0], 1);

        vm.startPrank(user2);

        vm.expectRevert("Caller Not Owner Of Token");
        spitYard.unstake(tokenIdsUnstake);

        userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 1);
        assertEq(userStake[0], 1);
    }

    function test_unstake_fail_notStaked() public {
        uint256[] memory tokenIdsUnstake = new uint256[](1);
        tokenIdsUnstake[0] = 1;

        vm.startPrank(user1);

        vm.expectRevert("Caller Not Owner Of Token");
        spitYard.unstake(tokenIdsUnstake);

        uint256[] memory userStake = spitYard.getUserStake(user1);

        assertEq(userStake.length, 0);
    }

    function test_setSpitBuddies_success() public {
        address _spitBuddies = makeAddr("spitBuddies");
        spitYard.setSpitBuddies(_spitBuddies);

        assertEq(address(spitYard.spitBuddies()), _spitBuddies);
    }

    function test_setSpitBuddies_fail_notOwner() public {
        address _spitBuddies = makeAddr("spitBuddies");

        vm.startPrank(nonOwner);

        vm.expectRevert("Ownable: caller is not the owner");
        spitYard.setSpitBuddies(_spitBuddies);

        assertEq(address(spitYard.spitBuddies()), address(spitBuddies));
    }

    function test_setStakingPaused_success() public {
        spitYard.setStakingPaused(true);

        assertEq(spitYard.stakingPaused(), true);
    }

    function test_setStakingPaused_fail_notOwner() public {
        vm.startPrank(nonOwner);

        vm.expectRevert("Ownable: caller is not the owner");
        spitYard.setStakingPaused(true);

        assertEq(spitYard.stakingPaused(), false);
    }

    function test_setJiraCentral_sucess() public {
        address _jiraCentral = makeAddr("jiraCentral");
        spitYard.setJiraCentral(_jiraCentral);

        assertEq(address(spitYard.jiraCentral()), _jiraCentral);
    }

    function test_setJiraCentral_fail_notOwner() public {
        address _jiraCentral = makeAddr("jiraCentral");

        vm.startPrank(nonOwner);

        vm.expectRevert("Ownable: caller is not the owner");
        spitYard.setJiraCentral(_jiraCentral);

        assertEq(address(spitYard.jiraCentral()), address(jiraCentral));
    }

    function test_balanceOf_success() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.startPrank(user1);

        spitYard.stake(tokenIds);

        assertEq(spitYard.balanceOf(user1), 1);
    }
}
