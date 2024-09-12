// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./token.sol";
import "./calculate.sol";

contract P2PLending is Token, Calculator{

    struct Depositor{
        uint depositeAmount;//总代币数目
        uint canLendAmount;//可借出的代币数目
    }

    struct Borrower{
        uint collateralAmount;//借款人提供的总抵押品金额
        uint canBorrowCollateralAmount;//可以用于借款的可用抵押品金额
        uint totalBorrowAmount;//所借的总金额
        uint borrowAmountRepaid;//借款人已偿还的贷款金额
    }

    //配置借款条款
    struct BorrowOption{
        uint maxAmount;//最大可借数目
        uint minAmount;//最小可借数目
        uint interestRate;//利率
        uint maxTimeBeforeReturn;//最长还款时间
        uint collateralRate;//质押率
        bool isActive;//借款选项是否可用
    }

    //具体的借款记录，记录每笔借款的实际情况
    struct BorrowRecord{
        uint amount;//借款人该笔所借的金额。
        uint repaidAmount;//借款人已偿还该笔的金额
        uint startedTime;//该笔借款开始的时间戳
        uint endsTime;//该笔借款到期的时间戳
        uint interestRate;//利率
        uint collateralRate;//质押率
        address depositor;
        bool isActive;//借款是否仍然有效
    }



    mapping(address => Depositor) public depositors;

    mapping(address => BorrowOption[]) public borrowOptions;//数组是因为一个账户可以有不同借款条例供选择

    mapping(address => Borrower) public borrowers;

    mapping(address => BorrowRecord[]) public borrowRecords;



    modifier onlyDepositor() {
        //要求存款数目大于0
        require(depositors[msg.sender].depositeAmount > 0, "Not a depositor");
        _;
    }

    modifier onlyBorrower() {
        //要求质押数量大于0
        require(borrowers[msg.sender].collateralAmount > 0, "Not a borrower");
        _;
      }

    modifier onlyValidBorrowOption(address _depositor, uint256 index) {
        require(borrowOptions[_depositor][index].isActive, "BorrowOption is not active");
        //_depositor为key，index是数组索引
        _;
    }


    //每次最少可存款金额
    uint minDeposit=0;
    //代币的兑换比率
    uint exchangeRate;
    //设定最少可存款金额
    function  setMinDeposit(uint _minDeposit) public onlyOwner{
        minDeposit = _minDeposit;
    }

    function  seeMinDeposit() public view returns(uint){
        return minDeposit;
    }

    function seetokentype() public view returns(IERC20){
        return token;
    }
///////**************存款人相关函数****************\\\\\\\\\

    //存款人初始化
    function registerDepositor() public {
        require(depositors[msg.sender].depositeAmount == 0, "Depositor already registered");
        depositors[msg.sender] = Depositor(0, 0);
    }

//存钱
function depositMoney(uint _amount) public {
    require(minDeposit > 0, "Set minDeposit first!");
    require(_amount >= minDeposit, "Amount should be greater than minDeposit");
    
    // 先进行授权
    token.approve(msg.sender, _amount);
    
    // 然后转移代币到合约
    token.transferFrom(msg.sender, address(this), _amount);

    // 更新存款信息
    depositors[msg.sender].depositeAmount += _amount;
    depositors[msg.sender].canLendAmount += _amount;

    emit Deposit(msg.sender, _amount);
}

// 定义 Deposit 事件
event Deposit(address indexed user, uint256 amount);

    //增加新借贷条款
    function addBorrowOption(
        uint _maxAmount,
        uint _minAmount,
        uint _interestRate,
        uint _maxTimeBeforeReturn,
        uint _collateralRate
    ) public onlyDepositor {
        borrowOptions[msg.sender].push(
            BorrowOption(
                _maxAmount,
                _minAmount,
                _interestRate,
                _maxTimeBeforeReturn,
                _collateralRate,
                true
            )
        );
    }

    //启动/关闭借贷条款
    function adjustBorrowOption(uint256 index, bool _isActive) public onlyDepositor {
        borrowOptions[msg.sender][index].isActive = _isActive;
    }

///////**************借款人相关函数****************\\\\\\\\\

    //借款人初始化
    function registerBorrower() public {
        require(borrowers[msg.sender].collateralAmount == 0, "Borrower already registered");
        borrowers[msg.sender] = Borrower(0, 0, 0, 0);
    }

    //质押
    function depositCollateral(uint256 _amount) public {
        require(_amount >= minDeposit, "Amount is too low");
        token.approve(address(this), type(uint256).max);
        //往合约里存钱
        token.transferFrom(msg.sender, address(this), _amount);
        //更新借款信息
        borrowers[msg.sender].collateralAmount += _amount;
        borrowers[msg.sender].canBorrowCollateralAmount += _amount;
    }

    //获得能借的总额
    function _getcanBorrowCollateralAmount(address _borrower) internal view returns (uint256) {
        return borrowers[_borrower].canBorrowCollateralAmount; 
    }



///////**************借款相关函数****************\\\\\\\\\

    //获取需要的质押数量
    function getRequiredCollateral(
       address _depositor, 
       uint256 _index, 
       uint256 _amount
        ) internal view returns (uint) {
            return (calcCollateralAmount(_amount, borrowOptions[_depositor][_index].collateralRate));//计算质押数量
    }
     
    //获取能用的质押数量
    function getCanBorrowCollateral(address _borrower) internal view returns (uint) {
        return borrowers[_borrower].canBorrowCollateralAmount; 
    }

    //借款
    function borrowMoney(
        address _depositor,
        uint _index,
        uint _amount,
        uint _maxTimeBeforeReturn
    ) public onlyBorrower onlyValidBorrowOption(_depositor, _index) {
        uint requiredCollateral = getRequiredCollateral(_depositor, _index, _amount);
        require(
            getCanBorrowCollateral(msg.sender) >= requiredCollateral,
            "Don't have enough Collateral!"
        );//借款人能用的质押数量要够
        require(
            depositors[_depositor].canLendAmount >= _amount,
            "Amount is beyond the deposit!"
        );//存款人能借出的金额要够
        require(
            borrowOptions[_depositor][_index].maxTimeBeforeReturn >= _maxTimeBeforeReturn,
            "Return time is too long"
        );//还款时间要在条例里的还款期限内

        //更新存款人和借款人的存款
        depositors[_depositor].canLendAmount -= _amount;//存款人能借出金额减少
        borrowers[msg.sender].canBorrowCollateralAmount -= requiredCollateral;//借款人质押的数目减少
        borrowers[msg.sender].totalBorrowAmount += _amount;//借款人的借款总额增加

        //创建一个新的借款记录
        borrowRecords[msg.sender].push(BorrowRecord(
            _amount,
            0,
            block.timestamp,
            block.timestamp+_maxTimeBeforeReturn,
            borrowOptions[_depositor][_index].interestRate,
            borrowOptions[_depositor][_index].collateralRate,
            _depositor,
            true
        ));

        //将代币从合约转给借款人
        transferTokensToUser(msg.sender,_amount);
    }


///////**************还款相关函数****************\\\\\\\\\

    function repay(uint _index, uint _amount) public onlyBorrower {
        require(borrowRecords[msg.sender][_index].isActive,
        "This credit is not Active!");
        //还差多少没还
        uint leftAmount = borrowRecords[msg.sender][_index].amount - borrowRecords[msg.sender][_index].repaidAmount;
        //借了多久，用来计算利率
        uint timePastsBy = block.timestamp - borrowRecords[msg.sender][_index].startedTime;
        //每秒利率
        uint interestRatePerSecond = calcInterestRatePerSecond(borrowRecords[msg.sender][_index].interestRate);
        //利息
        uint interest = calcInterest(_amount, interestRatePerSecond, timePastsBy);
        //连本带利
        uint totalAmount = leftAmount+interest;

        require(_amount <= totalAmount, "Amount is too high, man!");
        require(_amount > interest, "Amount is too low, man!");

        //拿钱
        token.transferFrom(msg.sender, address(this), _amount);

        //更新借款人信息
        uint amountAfterInterest = _amount - interest;
        borrowers[msg.sender].borrowAmountRepaid += amountAfterInterest;
        //更新借款记录
        borrowRecords[msg.sender][_index].repaidAmount += amountAfterInterest;
        //更新存款人信息
        depositors[borrowRecords[msg.sender][_index].depositor].canLendAmount += _amount;
        depositors[borrowRecords[msg.sender][_index].depositor].depositeAmount += interest;

    }

}