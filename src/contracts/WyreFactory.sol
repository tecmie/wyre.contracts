// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Wyre} from "./Wyre.sol";

/**
* @title Wyre Factory.
* @author Tecmie Labs.
* @notice Version: v0.0.1.
* @dev Deploys Wyre. Anyone can be able to deploy Wyre for a small, changeable fee.
*/
contract WyreFactory is Ownable {
    error LowFee();
    event SetPrice(uint256 oldPrice, uint256  newPrice);

    uint256 private deploymentPrice = 0.1 ether;

    receive() external payable {}

    constructor() {
        emit SetPrice(0, 0.1 ether);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        uint256 oldPrice = deploymentPrice;
        deploymentPrice = newPrice;
        emit SetPrice(oldPrice, newPrice);
    }

    function deployWyre() external payable returns (address) {
        if (msg.value < deploymentPrice) revert LowFee();
        Wyre wyre = new Wyre();
        wyre.transferOwnership(msg.sender);
        return address(wyre);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Wyre: Call to external address failed!");
    }
}