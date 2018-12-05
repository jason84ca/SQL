/* Assignment 2 - Vu Duc Nguyen

Question 1: Create a database named db_{yourfirstname}
Question 2:
Create Customer table with at least the following columns: (1/2 mark)
CustomerID INT NOT NULL
FirstName Nvarchar(50 ) NOT NULL
LastName Nvarchar(50) NOT NULL*/
USE db_VUDUC
GO

CREATE TABLE Customer
(
CustomerID int NOT NULL,
FirstName Nvarchar(50) NOT NULL,
LastName Nvarchar(50) NOT NULL
)

/* Question 3:
Create Orders table as follows: (1/2 mark)
OrderID INT Not NULL
CustomerID INT NOT NULL
OrderDate datetime Not NULL*/
CREATE TABLE Orders
(
OrderID int NOT NULL,
CustomerID int NOT NULL,
OrderDate datetime NOT NULL
)

/* Question 4:
Use triggers to impose the following constraints (4 marks)
a)   A Customer with Orders cannot be deleted from Customer table.
b)   Create a custom error and use Raiserror to notify.
c)   If CustomerID is updated in Customers, referencing rows in Orders must be updated accordingly.
d)   Updating and Insertion of rows in Orders table must verify that CustomerID exists in Customer table, otherwise 
Raiserror to notify.*/

-- Question 4. a, b
CREATE TRIGGER test ON Customer
AFTER DELETE
AS
DECLARE @error Nvarchar (100)
SET @error = 'Cannot delete rows having CustomerID in Orders table'
IF EXISTS (SELECT DELETED.CustomerID FROM DELETED WHERE DELETED.CustomerID IN (SELECT CustomerID FROM Orders)) 
	BEGIN
		RAISERROR (@error,16,1);
		ROLLBACK TRANSACTION;
	END

-- Question 4.c

CREATE TRIGGER test1 ON Customer
AFTER UPDATE
AS
DECLARE @old int, @new int
SELECT @old = CustomerID FROM DELETED
SELECT @new = CustomerID FROM INSERTED
IF EXISTS(SELECT * FROM Orders WHERE Orders.CustomerID = @old)
	BEGIN
		UPDATE Orders
		SET CustomerID = @new 
		WHERE CustomerID = @old
	END

-- Question 4.d
CREATE TRIGGER test2 ON Orders
AFTER INSERT, UPDATE
AS
IF NOT EXISTS (SELECT Customer.CustomerID FROM Customer, INSERTED WHERE Customer.CustomerID = INSERTED.CustomerID)
	BEGIN
		RAISERROR ('Cannot insert this data into Orders table',16,1);
		ROLLBACK TRANSACTION;
	END

/* Question 5:
Create a scalar function named fn_CheckName(@FirstName, @LastName) to check that the FirstName and LastName are not the 
same. (2 marks)*/

CREATE FUNCTION fn_CheckName
(
	@FirstName Nvarchar(50),
	@LastName Nvarchar(50)
)
RETURNS INT
AS
BEGIN
DECLARE @check INT
IF @FirstName = @LastName 
	SET @check = 1
ELSE IF @FirstName != @LastName
	SET @check = 0
RETURN @check
END

/* Question 6:
Create a stored procedure called sp_InsertCustomer that would take Firstname and Lastname and optional CustomerID as 
parameters and Insert into Customer table.
a) If CustomerID is not provided, increment the last CustomerID and use that.
b) Use the CheckName function to verify that the customer name is correct. (4 marks)*/

DROP PROCEDURE sp_InsertCustomer
CREATE PROCEDURE sp_InsertCustomer
	@FN Nvarchar(50),
	@LN Nvarchar(50),
	@id int = null
AS
IF dbo.fn_CheckName (@FN, @LN) = 1
	PRINT 'The Customer name is not correct ! (FirstName = LastName)'
ELSE IF dbo.fn_CheckName (@FN, @LN) = 0
	BEGIN
		IF @id IS NULL OR @id IN (SELECT CustomerID FROM Customer)
			BEGIN
				SET @id = (SELECT MAX(CustomerID) FROM Customer) + 1
				INSERT INTO Customer
				VALUES (@id, @FN, @LN)
			END
	END

/* Question 7:
Log all updates to Customer table to CusAudit table. Indicate the previous and new values of data, the date and time and 
the login name of the person who made the changes. (4 marks)*/

CREATE TABLE CusAudit
(
PreCustomerID int,
PreFirstName Nvarchar(50),
PreLastName Nvarchar(50),
NewCustomerID int,
NewFirstName Nvarchar (50),
NewLastName Nvarchar(50),
ChangedTime Datetime,
ChangedUser Nvarchar(50) NOT NULL DEFAULT CURRENT_USER
)

CREATE TRIGGER LogUpdate ON Customer
AFTER INSERT, DELETE, UPDATE
AS
DECLARE @Now DATETIME
SET @Now = GETDATE()

-- Delete action
INSERT INTO CusAudit (PreCustomerID, PreFirstName, PreLastName, NewCustomerID, NewFirstName, NewLastName, ChangedTime)
SELECT DELETED.CustomerID, DELETED.FirstName, DELETED.LastName, NULL, NULL, NULL, @Now
FROM DELETED

-- Insert action
INSERT INTO CusAudit (PreCustomerID, PreFirstName, PreLastName, NewCustomerID, NewFirstName, NewLastName, ChangedTime)
SELECT NULL, NULL, NULL, INSERTED.CustomerID, INSERTED.FirstName, INSERTED.LastName, @Now
FROM INSERTED
