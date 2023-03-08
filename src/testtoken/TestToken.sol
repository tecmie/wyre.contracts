// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TST") {
        _mint(msg.sender, type(uint256).max);
    }
}