// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./ownable.sol";
contract Token is Ownable{
    //代币合约的地址
    address tokenAddress;
    IERC20 token;
    address collateralTokenAddress;
    IERC20 collateral;

    address public constant WBTC = address(0x29f2D40B0605204364af54EC677bD022dA425d03);
    address public constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public constant USDC = address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8);
    address public constant USDT = address(0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0);

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