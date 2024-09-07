// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./basic.sol";
contract Token is Basic{
    //代币合约的地址
    address tokenAddress;
    IERC20 token;
    address collateralTokenAddress;
    IERC20 collateral;

    //设定代币的类型
    function setToken(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
        token = IERC20(tokenAddress);
    }

    //设定质押的代币类型
    function setCollateralToken(address _collateralTokenAddress) public onlyOwner {
        collateralTokenAddress = _collateralTokenAddress;
        collateral = IERC20(collateralTokenAddress);
    }

    //从某账户获得代币
    function getTokensFromUser(address from, uint256 amount) public {
        require(token.transferFrom(from, address(this), amount), "Transfer failed");
    }

    //给某账户转代币
    function transferTokensToUser(address to, uint256 amount) internal {
        require(token.transfer(to, amount), "Transfer failed");
    }

    //从某账户得到质押代币
    function getCollateralFromUser(address from, uint256 amount) public {
        require(collateral.transferFrom(from, address(this), amount), "Transfer failed");
    }

}