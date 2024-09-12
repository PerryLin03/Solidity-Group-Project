//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Calculator {
    uint public DECIMAL = 10 ** 18;//用于保持精度
    uint public SECONDS_IN_YEAR = 31536000;

    //每秒利率
    function calcInterestRatePerSecond(uint256 interestRate) public view returns (uint256) {
        return interestRate/SECONDS_IN_YEAR; 
    }
    //计算利息
    function calcInterest(uint256 amount, uint256 interestRate, uint256 duration) public view returns (uint256) {
        return amount * interestRate * duration / DECIMAL;
    }
    //计算质押
    function calcCollateralAmount(uint256 amount, uint256 collateralRate) public view returns (uint256) {
        return amount * collateralRate / DECIMAL;
    }

}