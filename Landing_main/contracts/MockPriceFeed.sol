// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockPriceFeed {
    int256 public price;
    uint8 public decimals;

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }

    function setPrice(int256 _price) external {
        price = _price;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, price, block.timestamp, block.timestamp, 0);
    }
}
