// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MockSpit is ERC20, Ownable {
    constructor() ERC20("MockSpit", "MOCK") {
        uint256 amt = 1000 ether;
        mint(msg.sender, amt);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
