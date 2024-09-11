let web3;
let contract;
const contractAddress = "YOUR_CONTRACT_ADDRESS"; // Replace with your deployed contract address
const contractABI = [/* YOUR_CONTRACT_ABI */];  // Replace with your contract ABI

async function connectWallet() {
    if (window.ethereum) {
        web3 = new Web3(window.ethereum);
        try {
            await window.ethereum.enable();
            const accounts = await web3.eth.getAccounts();
            document.getElementById("wallet-address").innerText = `Connected: ${accounts[0]}`;
            contract = new web3.eth.Contract(contractABI, contractAddress);
        } catch (error) {
            console.error("User denied account access", error);
        }
    } else {
        alert("Please install MetaMask!");
    }
}

// Depositor functions
async function registerDepositor() {
    const accounts = await web3.eth.getAccounts();
    await contract.methods.registerDepositor().send({ from: accounts[0] });
}

async function depositMoney() {
    console.log("depositMoney function called");
    const accounts = await web3.eth.getAccounts();
    const amount = document.getElementById("deposit-amount").value;
    console.log("Deposit Amount:", amount);
    try {
        await contract.methods.depositMoney(amount).send({ from: accounts[0] });
        console.log("Deposit successful");
    } catch (error) {
        console.error("Error depositing money:", error);
    }
}

async function addBorrowOption() {
    const accounts = await web3.eth.getAccounts();
    const maxAmount = document.getElementById("maxAmount").value;
    const minAmount = document.getElementById("minAmount").value;
    const interestRate = document.getElementById("interestRate").value;
    const collateralRate = document.getElementById("collateralRate").value;
    const maxTime = document.getElementById("maxTime").value;
    await contract.methods.addBorrowOption(maxAmount, minAmount, interestRate, maxTime, collateralRate).send({ from: accounts[0] });
}

// Borrower functions
async function registerBorrower() {
    const accounts = await web3.eth.getAccounts();
    await contract.methods.registerBorrower().send({ from: accounts[0] });
}

async function depositCollateral() {
    const accounts = await web3.eth.getAccounts();
    const amount = document.getElementById("collateral-amount").value;
    await contract.methods.depositCollateral(amount).send({ from: accounts[0] });
}

// Borrow money
async function borrowMoney() {
    const accounts = await web3.eth.getAccounts();
    const depositorAddress = document.getElementById("depositor-address").value;
    const index = document.getElementById("borrow-index").value;
    const amount = document.getElementById("borrow-amount").value;
    const maxTime = document.getElementById("borrow-time").value;
    await contract.methods.borrowMoney(depositorAddress, index, amount, maxTime).send({ from: accounts[0] });
}

// Repay loan
async function repay() {
    const accounts = await web3.eth.getAccounts();
    const index = document.getElementById("repay-index").value;
    const amount = document.getElementById("repay-amount").value;
    await contract.methods.repay(index, amount).send({ from: accounts[0] });
}