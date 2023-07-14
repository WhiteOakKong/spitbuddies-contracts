//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <=0.9.0;

import { JiraCentral } from "../src/JiraCentral.sol";
import { SpitBuddies } from "../src/SpitBuddies.sol";
import { SpitYard } from "../src/SpitYard.sol";
import { SpitDispenser } from "../src/SpitDispenser.sol";

import { BaseScript } from "./Base.s.sol";

contract Deploy is BaseScript {
    function run() public broadcast {
        address checkpointManager = 0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287;
        address fxRoot = 0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2;
        address fxChild = 0x8397259c983751DAf40400790063935a11afa28a;

        vm.createSelectFork(vm.rpcUrl("mainnet"));
        address jiraCentral = address(new JiraCentral());
        address spitBuddies = address(new SpitBuddies());
        address spitYard = address(new SpitYard(checkpointManager, fxRoot, spitBuddies));

        // create and select fork for goerli
        vm.createSelectFork(vm.rpcUrl("goerli"));
        address spitDispenser = address(new SpitDispenser(fxChild, spitYard));
    }
}
