import sqlite3

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
         CREATE TABLE borrowoption (
            Depositor_address` VARCHAR(45) NOT NULL,
            maxAmount INT NOT NULL DEFAULT 0,
            minAmount INT NOT NULL DEFAULT 0,
            interestRate int NOT NULL DEFAULT 0,
            maxTimeBeforeReturn INT NOT NULL DEFAULT 0,
            collateralRate int NOT NULL DEFAULT 0,
            isActive SET("true", "false") NOT NULL DEFAULT 'false'
        );
    ''')

    # 创建 borrower 表
    c.execute('''
        CREATE TABLE borrower (
          canBorrowCollateralAmount INT NOT NULL DEFAULT 0,
          Borrower_address VARCHAR(45) NOT NULL,
          collateralAmount INT NOT NULL DEFAULT 0,
          totalBorrowAmount INT NOT NULL DEFAULT 0,
          borrowAmountRepaid INT NOT NULL DEFAULT 0
          );
    ''')

    # 创建 borrowrecord 表
    c.execute('''
          CREATE TABLE borrowrecord (              
            Depositor_address varchar(45) NOT NULL,
            amount int NOT NULL DEFAULT '0',
            repaidAmount int NOT NULL DEFAULT '0',
            startedTime int NOT NULL DEFAULT '0',
            endsTime int NOT NULL DEFAULT '0',
            interestRate int NOT NULL DEFAULT '0',
            collateralRate int NOT NULL DEFAULT '0',
            isActive set('true','false') NOT NULL DEFAULT 'false'
         )
    ''')

    # 提交更改并关闭连接
    conn.commit()
    c.close()
    conn.close()

if __name__ == '__main__':
    create_database()
