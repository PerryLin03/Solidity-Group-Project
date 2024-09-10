create DATABASE customer;
use customer;
CREATE TABLE `customer`.`depositor` (
  `Depositor_address` VARCHAR(45) NOT NULL,
  `depositeAmount` INT NOT NULL DEFAULT 0,
  `canLendAmount` INT NOT NULL DEFAULT 0);
  CREATE TABLE `customer`.`borrowoption` (
  `Depositor_address` VARCHAR(45) NOT NULL,
  `maxAmount` INT NOT NULL DEFAULT 0,
  `minAmount` INT NOT NULL DEFAULT 0,
  `interestRate` FLOAT NOT NULL DEFAULT 0,
  `maxTimeBeforeReturn` INT NOT NULL DEFAULT 0,
  `collateralRate` FLOAT NOT NULL DEFAULT 0,
  `isActive` SET("true", "false") NOT NULL DEFAULT 'false');
CREATE TABLE `customer`.`borrower` (
  `canBorrowCollateralAmount` INT NOT NULL DEFAULT 0,
  `Borrower_address` VARCHAR(45) NOT NULL,
  `collateralAmount` INT NOT NULL DEFAULT 0,
  `totalBorrowAmount` INT NOT NULL DEFAULT 0,
  `borrowAmountRepaid` INT NOT NULL DEFAULT 0);
CREATE TABLE `borrowrecord` (
  `Depositor_address` varchar(45) NOT NULL,
  `amount` int NOT NULL DEFAULT '0',
  `repaidAmount` int NOT NULL DEFAULT '0',
  `startedTime` int NOT NULL DEFAULT '0',
  `endsTime` int NOT NULL DEFAULT '0',
  `interestRate` double NOT NULL DEFAULT '0',
  `collateralRate` double NOT NULL DEFAULT '0',
  `isActive` set('true','false') NOT NULL DEFAULT 'false'
)
