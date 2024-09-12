from flask import Flask,render_template,request
import sqlite3
dapp=Flask(__name__)

@dapp.route('/',methods=["get","post"])
def P2Plending():
    return render_template('P2Plending.html')


def create_database():
    # 连接数据库，如果不存在则自动创建
    conn = sqlite3.connect('dapp.db')
    c = conn.cursor()
    
    # 创建 depositor 表
    c.execute('''
        CREATE TABLE if not exists depositor (
  Depositor_address VARCHAR(45) NOT NULL,
  depositeAmount INT NOT NULL DEFAULT 0,
  canLendAmount INT NOT NULL DEFAULT 0);
    ''')
    
    # 创建 borrowoption 表
    c.execute('''
         CREATE TABLE if not exists borrowoption (
            Depositor_address VARCHAR(45) NOT NULL,
            maxAmount INT NOT NULL DEFAULT 0,
            minAmount INT NOT NULL DEFAULT 0,
            interestRate int NOT NULL DEFAULT 0,
            maxTimeBeforeReturn INT NOT NULL DEFAULT 0,
            collateralRate int NOT NULL DEFAULT 0,
            isActive INT NOT NULL DEFAULT 'false'
        );
    ''')

    # 创建 borrower 表
    c.execute('''
        CREATE TABLE if not exists borrower (
          canBorrowCollateralAmount INT NOT NULL DEFAULT 0,
          Borrower_address VARCHAR(45) NOT NULL,
          collateralAmount INT NOT NULL DEFAULT 0,
          totalBorrowAmount INT NOT NULL DEFAULT 0,
          borrowAmountRepaid INT NOT NULL DEFAULT 0
          );
    ''')

    # 创建 borrowrecord 表
    c.execute('''
          CREATE TABLE if not exists borrowrecord (              
            Depositor_address varchar(45) NOT NULL,
            amount int NOT NULL DEFAULT '0',
            repaidAmount int NOT NULL DEFAULT '0',
            startedTime int NOT NULL DEFAULT '0',
            endsTime int NOT NULL DEFAULT '0',
            interestRate int NOT NULL DEFAULT '0',
            collateralRate int NOT NULL DEFAULT '0',
            isActive INT NOT NULL DEFAULT 'false'
         )
    ''')

    # 提交更改并关闭连接
    conn.commit()
    c.close()
    conn.close()
    return

if __name__=='__main__':
    create_database()
    dapp.run()
