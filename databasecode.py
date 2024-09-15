	#插入借款人信息
    borrower_address = request.form.get("Borrower_address")
    collateral_amount = request.form.get("collateral_amount")
    maxAmount = request.form.get("maxAmount")
    minAmount = request.form.get("minAmount")
    interestRate = request.form.get("interestRate")
    conn = sqlite3.connect('dapp.db')
    c = conn.cursor()
    c.execute("insert into user values (?,?,?,?,?,?,?)",
	(borrower_address,collateral_amount,maxAmount,interestRate,maxTime,minAmount,interestRate))
    conn.commit()
    c.close()
    conn.close()

#插入存款人信息
    depositor_address = request.form.get("depositor_address")
    min_deposit_amount = request.form.get("min_deposit_amount")
    deposit_amount = request.form.get("deposit_amount")
    conn = sqlite3.connect('dapp.db')
    c = conn.cursor()
    c.execute("insert into user values (?,?,?)",
	(depositor_address,min_deposit_amount,deposit_amount))
    conn.commit()
    c.close()
    conn.close()

#插入借款条约信息
    depositor_address = request.form.get("depositor_address")
    borrow_index = request.form.get("borrow_index")
    maxAmount = request.form.get("maxAmount")
    minAmount = request.form.get("minAmount")
    interestRate = request.form.get("interestRate")
    collateralRate = request.form.get("collateralRate")
    maxTime = request.form.get("maxTime")
    act = 1
    conn = sqlite3.connect('dapp.db')
    c = conn.cursor()
    c.execute("insert into user values (?,?,?,?,?,?,?)",
	(depositor_address,maxAmount,minAmount,interestRate,maxTime,collateralRate,act))
    conn.commit()
    c.close()
    conn.close()

#插入借款记录信息
r = request.form.get("q")
    current_time =datetime.datetime.now()
    conn = sqlite3.connect('dapp.db')
    c = conn.cursor()
    c.execute("insert into user values (?,?)",(r,current_time))
    conn.commit()
    c.close()
    conn.close()
    return render_template('main.html',r=r)
