const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EnhancedLendingProtocol", function () {
  let contract;
  let owner, user1, user2;
  let usdc, usdt, priceFeedMock;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Mock ERC20 token
    const ERC20Mock = await ethers.getContractFactory("MockERC20");
    usdc = await ERC20Mock.deploy("USD Coin", "USDC", 6);
    usdt = await ERC20Mock.deploy("Tether", "USDT", 6);
    await usdc.deployed();
    await usdt.deployed();

    // Mock Chainlink price feed
    const PriceFeedMock = await ethers.getContractFactory("MockPriceFeed");
    priceFeedMock = await PriceFeedMock.deploy(8); // Price feed with 8 decimals
    await priceFeedMock.deployed();

    // Deploy EnhancedLendingProtocol
    const EnhancedLendingProtocol = await ethers.getContractFactory("EnhancedLendingProtocol");
    contract = await EnhancedLendingProtocol.deploy();
    await contract.deployed();

    // Initialize USDC and USDT in the protocol
    await contract.initializeAsset(usdc.address, usdc.address, priceFeedMock.address);
    await contract.initializeAsset(usdt.address, usdt.address, priceFeedMock.address);
  });

  it("should allow deposits and update user balances", async function () {
    const depositAmount = ethers.utils.parseUnits("1000", 6); // 1000 USDC
    await usdc.connect(user1).approve(contract.address, depositAmount);
    await contract.connect(user1).deposit(usdc.address, depositAmount);

    const userDeposit = await contract.userDeposits(usdc.address, user1.address);
    expect(userDeposit.amount).to.equal(depositAmount);
  });

  it("should calculate max borrowable amounts correctly", async function () {
    const depositAmount = ethers.utils.parseUnits("1000", 6); // 1000 USDC
    await usdc.connect(user1).approve(contract.address, depositAmount);
    await contract.connect(user1).deposit(usdc.address, depositAmount);

    // Mock the price of USDC (1 USDC = 1 USD)
    await priceFeedMock.setPrice(ethers.utils.parseUnits("1", 8)); // 1 USDC = $1

    const collateralAmount = ethers.utils.parseUnits("1000", 6); // 1000 USDC
    const maxBorrowAmount = await contract.getMaxBorrowAmount(usdt.address, usdc.address, collateralAmount);

    const expectedMaxBorrow = collateralAmount.mul(100).div(150); // 150% collateralization ratio
    expect(maxBorrowAmount).to.equal(expectedMaxBorrow);
  });

  it("should allow borrowing and update user balances", async function () {
    const depositAmount = ethers.utils.parseUnits("1000", 6); // 1000 USDC
    await usdc.connect(user1).approve(contract.address, depositAmount);
    await contract.connect(user1).deposit(usdc.address, depositAmount);

    // Mock the price of USDC and USDT
    await priceFeedMock.setPrice(ethers.utils.parseUnits("1", 8)); // 1 USDC = $1

    const borrowAmount = ethers.utils.parseUnits("500", 6); // Borrow 500 USDT
    await contract.connect(user1).borrow(usdt.address, usdc.address, borrowAmount);

    const userBorrow = await contract.userBorrows(usdt.address, user1.address);
    expect(userBorrow.amount).to.equal(borrowAmount);
  });

  it("should allow repayment and update balances", async function () {
    const depositAmount = ethers.utils.parseUnits("1000", 6); // 1000 USDC
    await usdc.connect(user1).approve(contract.address, depositAmount);
    await contract.connect(user1).deposit(usdc.address, depositAmount);

    // Mock price feed
    await priceFeedMock.setPrice(ethers.utils.parseUnits("1", 8)); // 1 USDC = $1

    const borrowAmount = ethers.utils.parseUnits("500", 6);
    await contract.connect(user1).borrow(usdt.address, usdc.address, borrowAmount);

    await usdt.connect(user1).approve(contract.address, borrowAmount);
    await contract.connect(user1).repay(usdt.address, borrowAmount);

    const userBorrow = await contract.userBorrows(usdt.address, user1.address);
    expect(userBorrow.amount).to.equal(0);
  });
});
