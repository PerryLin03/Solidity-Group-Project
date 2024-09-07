//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "./ownable.sol";
contract Basic is Ownable{
    //每次最少可存款金额
    uint minDeposit;
    //代币的兑换比率
    uint exchangeRate;
    //设定最少可存款金额
    function  setMinDeposit(uint _minDeposit) public onlyOwner{
        minDeposit = _minDeposit;
    }
    

}
