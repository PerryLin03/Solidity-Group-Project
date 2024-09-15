// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EnhancedLendingProtocol is ReentrancyGuard, Ownable {
    // 資產資訊結構體
    struct AssetInfo {
        IERC20 token; // 資產對應的ERC20代幣合約
        AggregatorV3Interface priceFeed; // 資產對應的價格餵送（來自 Chainlink）
        uint256 totalDeposits; // 總存款量
        uint256 totalBorrows; // 總借款量
        uint256 reserveFactor; // 保留因子（用於計算平台的費用）
        uint256 lastUpdateTimestamp; // 上次更新的時間戳
        bool isActive; // 資產是否活躍（可用）
    }

    // 使用者存款資訊結構體
    struct UserDeposit {
        uint256 amount; // 存款數量
        uint256 lastUpdateTimestamp; // 上次更新時間戳
    }

    // 使用者借款資訊結構體
    struct UserBorrow {
        uint256 amount; // 借款數量
        uint256 lastUpdateTimestamp; // 上次更新時間戳
    }

    // 資產地址到資產資訊的映射
    mapping(address => AssetInfo) public assetInfo;
    // 使用者存款映射（資產地址 => 使用者地址 => 使用者存款）
    mapping(address => mapping(address => UserDeposit)) public userDeposits;
    // 使用者借款映射（資產地址 => 使用者地址 => 使用者借款）
    mapping(address => mapping(address => UserBorrow)) public userBorrows;

    // 常量資產地址
    address public constant WBTC = address(0x29f2D40B0605204364af54EC677bD022dA425d03); // WBTC 合約地址
    address public constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH 合約地址
    address public constant USDC = address(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8); // USDC 合約地址
    address public constant USDT = address(0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0); // USDT 合約地址

    // 倉位清算和利率常量
    uint256 public constant LIQUIDATION_THRESHOLD = 150; // 150% 的清算門檻
    uint256 public constant LIQUIDATION_BONUS = 2; // 清算人額外 2% 的獎勵
    uint256 public constant BORROW_RATE = 3e16; // 年借款利率 3%
    uint256 public constant DEPOSIT_RATE = 2e16; // 年存款利率 2%

    // Chainlink 價格餵送地址（Sepolia 測試網上）
    address public constant USDC_USD_PRICE_FEED = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
    address public constant USDT_USD_PRICE_FEED = 0xa82486565B8DCE64BFfaF1264BbC6197fb56fe9c;
    address public constant ETH_USD_PRICE_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address public constant BTC_USD_PRICE_FEED = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;

    // 合約的建構函數
    constructor() Ownable(msg.sender) {
        // 初始化資產價格餵送
        initializeAsset(USDC, USDC, USDC_USD_PRICE_FEED);
        initializeAsset(USDT, USDT, USDT_USD_PRICE_FEED);
        initializeAsset(ETH, ETH, ETH_USD_PRICE_FEED);
        initializeAsset(WBTC, WBTC, BTC_USD_PRICE_FEED);
    }

    // 初始化資產函數
    function initializeAsset(address asset, address tokenAddress, address priceFeedAddress) public onlyOwner {
        require(!assetInfo[asset].isActive, "Asset already initialized"); // 確保資產尚未初始化
        assetInfo[asset].token = IERC20(tokenAddress); // 設置資產代幣合約
        assetInfo[asset].priceFeed = AggregatorV3Interface(priceFeedAddress); // 設置價格餵送
        assetInfo[asset].isActive = true; // 標記為活躍
        assetInfo[asset].lastUpdateTimestamp = block.timestamp; // 記錄當前的時間戳
    }

    // 存款函數
    function deposit(address asset, uint256 amount) external payable nonReentrant {
        require(isAssetSupported(asset), "Asset not supported"); // 確保資產受支持
        updateInterest(asset); // 更新資產的利息

        if (asset == ETH) {
            require(msg.value == amount, "Incorrect ETH amount"); // 檢查傳入的 ETH 是否匹配
        } else {
            require(msg.value == 0, "ETH not accepted for this asset"); // 確保不是 ETH 資產
            require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "Transfer failed"); // 傳輸資產到合約
        }

        userDeposits[asset][msg.sender].amount += amount; // 更新使用者的存款
        userDeposits[asset][msg.sender].lastUpdateTimestamp = block.timestamp; // 更新時間戳
        assetInfo[asset].totalDeposits += amount; // 更新總存款量

        emit Deposit(msg.sender, asset, amount); // 觸發存款事件
    }

    // 提款函數
    function withdraw(address asset, uint256 amount) external nonReentrant {
        require(isAssetSupported(asset), "Asset not supported"); // 確保資產受支持
        updateInterest(asset); // 更新資產的利息

        UserDeposit storage userDeposit = userDeposits[asset][msg.sender];
        require(userDeposit.amount >= amount, "Insufficient balance"); // 確保使用者存款足夠

        userDeposit.amount -= amount; // 減少使用者存款
        userDeposit.lastUpdateTimestamp = block.timestamp; // 更新時間戳
        assetInfo[asset].totalDeposits -= amount; // 減少總存款量

        if (asset == ETH) {
            payable(msg.sender).transfer(amount); // 提款 ETH
        } else {
            require(IERC20(asset).transfer(msg.sender, amount), "Transfer failed"); // 提款其他資產
        }

        emit Withdraw(msg.sender, asset, amount); // 觸發提款事件
    }

    // 借款函數
    function borrow(address borrowAsset, address collateralAsset, uint256 borrowAmount) external nonReentrant {
        require(isAssetSupported(borrowAsset) && isAssetSupported(collateralAsset), "Asset not supported"); // 確保借貸和抵押資產均受支持
        require(borrowAsset != collateralAsset, "Cannot borrow the same asset as collateral"); // 確保借款和抵押資產不同
        updateInterest(borrowAsset); // 更新借貸資產的利息
        updateInterest(collateralAsset); // 更新抵押資產的利息

        uint256 collateralValue = getAssetValue(collateralAsset, userDeposits[collateralAsset][msg.sender].amount); // 計算抵押資產價值
        uint256 borrowValue = getAssetValue(borrowAsset, borrowAmount); // 計算借款資產價值

        require(collateralValue >= borrowValue * LIQUIDATION_THRESHOLD / 100, "Insufficient collateral"); // 確保抵押物價值足夠

        userBorrows[borrowAsset][msg.sender].amount += borrowAmount; // 更新使用者借款
        userBorrows[borrowAsset][msg.sender].lastUpdateTimestamp = block.timestamp; // 更新時間戳
        assetInfo[borrowAsset].totalBorrows += borrowAmount; // 更新總借款量

        if (borrowAsset == ETH) {
            payable(msg.sender).transfer(borrowAmount); // 借款 ETH
        } else {
            require(IERC20(borrowAsset).transfer(msg.sender, borrowAmount), "Transfer failed"); // 借款其他資產
        }

        emit Borrow(msg.sender, borrowAsset, borrowAmount, collateralAsset); // 觸發借款事件
    }

    // 還款函數
    function repay(address asset, uint256 amount) external payable nonReentrant {
        require(isAssetSupported(asset), "Asset not supported"); // 確保資產受支持
        updateInterest(asset); // 更新資產的利息

        UserBorrow storage userBorrow = userBorrows[asset][msg.sender];
        uint256 repayAmount = amount > userBorrow.amount ? userBorrow.amount : amount; // 確保還款數量不超過欠款

        if (asset == ETH) {
            require(msg.value >= repayAmount, "Insufficient ETH sent"); // 檢查傳入的 ETH 是否足夠
            if (msg.value > repayAmount) {
                payable(msg.sender).transfer(msg.value - repayAmount); // 返回多餘的 ETH
            }
        } else {
            require(IERC20(asset).transferFrom(msg.sender, address(this), repayAmount), "Transfer failed"); // 傳輸資產還款
        }

        userBorrow.amount -= repayAmount; // 減少使用者借款
        userBorrow.lastUpdateTimestamp = block.timestamp; // 更新時間戳
        assetInfo[asset].totalBorrows -= repayAmount; // 減少總借款量

        emit Repay(msg.sender, asset, repayAmount); // 觸發還款事件
    }

    // 清算函數
    function liquidate(address borrower, address borrowAsset, address collateralAsset) external payable nonReentrant {
        require(isAssetSupported(borrowAsset) && isAssetSupported(collateralAsset), "Asset not supported"); // 確保借貸和抵押資產均受支持
        updateInterest(borrowAsset); // 更新借貸資產的利息
        updateInterest(collateralAsset); // 更新抵押資產的利息

        require(isLiquidatable(borrower, borrowAsset, collateralAsset), "Position is not liquidatable"); // 檢查是否可以清算

        uint256 borrowAmount = userBorrows[borrowAsset][borrower].amount; // 獲取借款數量
        uint256 liquidationAmount = borrowAmount * LIQUIDATION_BONUS / 100; // 計算清算數量
        uint256 liquidatedCollateral = getAssetAmount(collateralAsset, getAssetValue(borrowAsset, liquidationAmount)); // 計算清算後獲得的抵押物

        userBorrows[borrowAsset][borrower].amount -= liquidationAmount; // 更新借款人的借款數量
        assetInfo[borrowAsset].totalBorrows -= liquidationAmount; // 減少總借款量
        userDeposits[collateralAsset][borrower].amount -= liquidatedCollateral; // 減少借款人的抵押物
        assetInfo[collateralAsset].totalDeposits -= liquidatedCollateral; // 減少總存款量

        if (borrowAsset == ETH) {
            require(msg.value >= liquidationAmount, "Insufficient ETH sent"); // 檢查傳入的 ETH 是否足夠
            if (msg.value > liquidationAmount) {
                payable(msg.sender).transfer(msg.value - liquidationAmount); // 返回多餘的 ETH
            }
        } else {
            require(IERC20(borrowAsset).transferFrom(msg.sender, address(this), liquidationAmount), "Transfer failed"); // 傳輸資產進行清算
        }

        if (collateralAsset == ETH) {
            payable(msg.sender).transfer(liquidatedCollateral); // 傳輸 ETH 作為清算後的抵押物
        } else {
            require(IERC20(collateralAsset).transfer(msg.sender, liquidatedCollateral), "Transfer failed"); // 傳輸其他資產作為清算後的抵押物
        }

        emit Liquidation(borrower, borrowAsset, collateralAsset, liquidationAmount, liquidatedCollateral); // 觸發清算事件
    }

    // 獲取使用者累計利息函數
    function getAccruedInterest(address asset, address user) external view returns (uint256) {
        UserBorrow storage userBorrow = userBorrows[asset][user];
        uint256 timePassed = block.timestamp - userBorrow.lastUpdateTimestamp; // 計算時間經過量
        return userBorrow.amount * BORROW_RATE * timePassed / (365 days * 1e18); // 計算累積利息
    }

    // 設定資產價格餵送地址
    function setAssetPriceFeed(address asset, address priceFeed) external onlyOwner {
        require(isAssetSupported(asset), "Asset not supported"); // 確保資產受支持
        assetInfo[asset].priceFeed = AggregatorV3Interface(priceFeed); // 設置新的價格餵送
        emit AssetPriceFeedUpdated(asset, priceFeed); // 觸發價格餵送更新事件
    }

    // 獲取資產價格
    function getAssetPrice(address asset) public view returns (uint256) {
        require(address(assetInfo[asset].priceFeed) != address(0), "Price feed not set"); // 確保價格餵送已設置
        (, int256 price,,,) = assetInfo[asset].priceFeed.latestRoundData(); // 從價格餵送獲取最新價格
        require(price > 0, "Invalid price"); // 確保價格有效
        return uint256(price); // 返回價格
    }

    // 獲取最大可借金額
    function getMaxBorrowAmount(address borrowAsset, address collateralAsset, uint256 collateralAmount) external view returns (uint256) {
        uint256 collateralValue = getAssetValue(collateralAsset, collateralAmount); // 計算抵押物價值
        uint256 maxBorrowValue = collateralValue * 100 / LIQUIDATION_THRESHOLD; // 計算最大可借金額
        return getAssetAmount(borrowAsset, maxBorrowValue); // 返回可借金額
    }

    // 檢查是否可清算
    function isLiquidatable(address borrower, address borrowAsset, address collateralAsset) public view returns (bool) {
        uint256 borrowAmount = userBorrows[borrowAsset][borrower].amount; // 獲取借款數量
        uint256 collateralAmount = userDeposits[collateralAsset][borrower].amount; // 獲取抵押物數量

        uint256 borrowValue = getAssetValue(borrowAsset, borrowAmount); // 計算借款資產價值
        uint256 collateralValue = getAssetValue(collateralAsset, collateralAmount); // 計算抵押物資產價值

        return collateralValue < borrowValue * LIQUIDATION_THRESHOLD / 100; // 判斷是否可清算
    }

    // 獲取資產價格餵送地址
    function getAssetPriceFeed(address asset) external view returns (address) {
        require(isAssetSupported(asset), "Asset not supported"); // 確保資產受支持
        return address(assetInfo[asset].priceFeed); // 返回價格餵送地址
    }

    // 更新資產的利息
    function updateInterest(address asset) internal {
        uint256 timePassed = block.timestamp - assetInfo[asset].lastUpdateTimestamp; // 計算時間經過
        if (timePassed > 0) {
            uint256 borrowInterest = assetInfo[asset].totalBorrows * BORROW_RATE * timePassed / (365 days * 1e18); // 計算借款利息
            uint256 depositInterest = assetInfo[asset].totalDeposits * DEPOSIT_RATE * timePassed / (365 days * 1e18); // 計算存款利息

            assetInfo[asset].totalBorrows += borrowInterest; // 更新總借款量
            assetInfo[asset].totalDeposits += depositInterest; // 更新總存款量
            assetInfo[asset].lastUpdateTimestamp = block.timestamp; // 更新時間戳
        }
    }

    // 檢查資產是否受支持
    function isAssetSupported(address asset) public view returns (bool) {
        return assetInfo[asset].isActive;
    }

    // 計算資產價值
    function getAssetValue(address asset, uint256 amount) internal view returns (uint256) {
        uint256 price = getAssetPrice(asset); // 獲取資產價格
        return price * amount / 1e8; // 假設價格有8位小數
    }

    // 計算資產數量
    function getAssetAmount(address asset, uint256 value) internal view returns (uint256) {
        uint256 price = getAssetPrice(asset); // 獲取資產價格
        return value * 1e8 / price; // 假設價格有8位小數
    }

    // 事件定義
    event Deposit(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Borrow(address indexed user, address indexed borrowAsset, uint256 amount, address indexed collateralAsset);
    event Repay(address indexed user, address indexed asset, uint256 amount);
    event Liquidation(address indexed borrower, address indexed borrowAsset, address indexed collateralAsset, uint256 liquidationAmount, uint256 liquidatedCollateral);
    event AssetPriceFeedUpdated(address indexed asset, address indexed priceFeed);
}
