from flask import Flask, render_template, request, jsonify
from web3 import Web3

app = Flask(__name__)

# 與區塊鏈網路（例如 Sepolia 測試網）建立連接
infura_url = "https://sepolia.infura.io/v3/your-infura-project-id"  # 使用你的 Infura 專案 ID
web3 = Web3(Web3.HTTPProvider(infura_url))

# 合約地址與 ABI
contract_address = "0x7660fFdD34a455F02D329E341F7A84642d3731CE"  # 替換為你的合約地址
abi = [
    # 在此填入你的合約 ABI
]

# 建立合約實例
contract = web3.eth.contract(address=contract_address, abi=abi)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/deposit', methods=['GET', 'POST'])
def deposit():
    if request.method == 'POST':
        # 獲取前端輸入的數據（例如資產和數量）
        asset = request.form['asset']
        amount = request.form['amount']

        # 在這裡可以添加與 Web3 合約的交互代碼
        # 如：contract.functions.deposit(asset, amount).transact({ 'from': your_wallet_address })

        return jsonify({'message': f'Successfully deposited {amount} {asset}'})

    return render_template('deposit.html')

@app.route('/borrow')
def borrow():
    return render_template('borrow.html')

@app.route('/repay', methods=['GET', 'POST'])
def repay():
    if request.method == 'POST':
        # 獲取前端數據並執行還款邏輯
        # 如：contract.functions.repay(asset, amount).transact({ 'from': your_wallet_address })
        return jsonify({'message': 'Repay successful'})

    return render_template('repay.html')

@app.route('/liquidation')
def liquidation():
    return render_template('liquidation.html')

if __name__ == '__main__':
    app.run(debug=True)
