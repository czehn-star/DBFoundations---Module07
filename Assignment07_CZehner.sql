--*************************************************************************--
-- Title: Assignment07
-- Author: CZehner
-- Desc: This file demonstrates how to use Functions
-- Change Log: When,Who,What
-- 2026-03-11,YourNameHere,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment07DB_YourNameHere')
	 Begin 
	  Alter Database [Assignment07DB_CZehner] set Single_user With Rollback Immediate;
	  Drop Database Assignment07DB_CZehner;
	 End
	Create Database Assignment07DB_CZehner;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment07DB_CZehner;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [money] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL
,[ProductID] [int] NOT NULL
,[ReorderLevel] int NOT NULL -- New Column 
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count], [ReorderLevel]) -- New column added this week
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock, ReorderLevel
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10, ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, abs(UnitsInStock - 10), ReorderLevel -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go


-- Adding Views (Module 06) -- 
Create View vCategories With SchemaBinding
 AS
  Select CategoryID, CategoryName From dbo.Categories;
go
Create View vProducts With SchemaBinding
 AS
  Select ProductID, ProductName, CategoryID, UnitPrice From dbo.Products;
go
Create View vEmployees With SchemaBinding
 AS
  Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID From dbo.Employees;
go
Create View vInventories With SchemaBinding 
 AS
  Select InventoryID, InventoryDate, EmployeeID, ProductID, ReorderLevel, [Count] From dbo.Inventories;
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From vCategories;
go
Select * From vProducts;
go
Select * From vEmployees;
go
Select * From vInventories;
go

/********************************* Questions and Answers *********************************/
Print
'NOTES------------------------------------------------------------------------------------ 
 1) You must use the BASIC views for each table.
 2) To make sure the Dates are sorted correctly, you can use Functions in the Order By clause!
------------------------------------------------------------------------------------------'
-- Question 1 (5% of pts):
-- Show a list of Product names and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the product name.

Select 
[Product Name] = ProductName
,[Unit Price] = Format(UnitPrice, 'C','en-US') -- Price, Currency, English US result 
From dbo.Products;

go

-- Question 2 (10% of pts): 
-- Show a list of Category and Product names, and the price of each product.
-- Use a function to format the price as US dollars.
-- Order the result by the Category and Product.

Select 
[Category Name] = c.CategoryName
,[Product Name] = p.ProductName
,[Unit Price] = Format(p.UnitPrice, 'C','en-US') -- Price, Currency, English US result 
From dbo.vProducts as p --Using the view rather than the base table
 JOIN dbo.vCategories as c
  On p.CategoryID = c.CategoryID
Order By c.CategoryName, p.ProductName;

go

-- Question 3 (10% of pts): 
-- Use functions to show a list of Product names, each Inventory Date, and the Inventory Count.
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

Select 
[ProductName] = p.ProductName
,[InventoryDate] = DateName(mm, i.InventoryDate) + ', ' + DateName(yyyy, i.InventoryDate)
,[InvetoryCount] = i.[Count] 
From dbo.vInventories as i 
 JOIN dbo.vProducts as p
  On i.ProductID = p.ProductID
Order By p.ProductName, i.InventoryDate;

go

-- Question 4 (10% of pts): 
-- CREATE A VIEW called vProductInventories. 
-- Shows a list of Product names, each Inventory Date, and the Inventory Count. 
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

Create View vProductInventories
 As
 Select --Reused code from previous question
[ProductName] = p.ProductName
,[InventoryDate] = DateName(mm, i.InventoryDate) + ', ' + DateName(yyyy, i.InventoryDate) 
,[InventoryCount] = i.[Count]
From dbo.vInventories as i
 Join dbo.vProducts as p
  On i.ProductID = p.ProductID;
go

Select * from vProductInventories --Checking that it works

go

-- Question 5 (10% of pts): 
-- CREATE A VIEW called vCategoryInventories. 
-- Shows a list of Category names, Inventory Dates, and a TOTAL Inventory Count BY CATEGORY
-- Format the date like 'January, 2017'.
-- Order the results by the Product and Date.

Create View vCategoryInventories
As
/*Select --Reused code from previous question
[CategoryName] = c.CategoryName
,[InventoryDate] = DateName(mm, i.InventoryDate) + ', ' + DateName(yyyy, i.InventoryDate) 
,[InventoryCount] = i.[Count]
From dbo.vInventories as i
 Join dbo.vCategories as c
  On i.CategoryID = c.CategoryID; --realized there is no common key between inventory and category
  */

Select 
 [CategoryName] = c.CategoryName
,[InventoryDate] = DateName(mm, i.InventoryDate) + ', ' + DateName(yyyy, i.InventoryDate)
,[InventoryCount] = Sum(i.[Count]) -- Sum up the count of all the product categories
From dbo.vInventories as i
 Join dbo.vProducts as p
  On i.ProductID = p.ProductID -- Had to use productID to bridge Inventory to Category
 Join dbo.vCategories as c
  On p.CategoryID = c.CategoryID
  Group By c.CategoryName, i.InventoryDate; --At first used "Order By" whihc doesnt work when creating views

go

Select * From vCategoryInventories; --Check to see if it worked
go

-- Question 6 (10% of pts): 
-- CREATE ANOTHER VIEW called vProductInventoriesWithPreviouMonthCounts. 
-- Show a list of Product names, Inventory Dates, Inventory Count, AND the Previous Month Count.
-- Use functions to set any January NULL counts to zero. 
-- Order the results by the Product and Date. 
-- This new view must use your vProductInventories view.

Create View vProductInventoriesWithPreviousMonthCounts
As
Select 
 [ProductName] = ProductName
,[InventoryDate] = InventoryDate
,[InventoryCount] = InventoryCount
--,[PreviousMonthCount] = (Lag(InventoryCount) Over(Partition By ProductName)
,[PreviousMonthCount] = Coalesce(Lag(InventoryCount) Over(Partition By ProductName Order By InventoryDate), 0)
From dbo.vProductInventories;

go
/*
I have tried multiple different way to stop getting a null value for the first row
but I keep getting 'null' values  on the first row of a new product? why does it not defaul to zero?
*/

Select * From vProductInventoriesWithPreviousMonthCounts; -- Verify the table view output

go

-- Question 7 (15% of pts): 
-- CREATE a VIEW called vProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- Varify that the results are ordered by the Product and Date.

Create View vProductInventoriesWithPreviousMonthCountsWithKPIs
As
Select 
 [ProductName] = ProductName
,[InventoryDate] = InventoryDate
,[InventoryCount] = InventoryCount
,[PreviousMonthCount] = PreviousMonthCount
,[KPI] = Case
  When InventoryCount > PreviousMonthCount Then 1
  When InventoryCount = PreviousMonthCount Then 0
  When InventoryCount < PreviousMonthCount Then -1
  End
From dbo.vProductInventoriesWithPreviousMonthCounts;
go

select * from vProductInventoriesWithPreviousMonthCountsWithKPIs --look at the table output 
-- Important: This new view must use your vProductInventoriesWithPreviousMonthCounts view!
-- Check that it works: Select * From vProductInventoriesWithPreviousMonthCountsWithKPIs;
go

-- Question 8 (25% of pts): 
-- CREATE a User Defined Function (UDF) called fProductInventoriesWithPreviousMonthCountsWithKPIs.
-- Show columns for the Product names, Inventory Dates, Inventory Count, the Previous Month Count. 
-- The Previous Month Count is a KPI. The result can show only KPIs with a value of either 1, 0, or -1. 
-- Display months with increased counts as 1, same counts as 0, and decreased counts as -1. 
-- The function must use the ProductInventoriesWithPreviousMonthCountsWithKPIs view.
-- Varify that the results are ordered by the Product and Date.

Create Function dbo.fProductInventoriesWithPreviousMonthCountsWithKPIs(@KPI int)
Returns Table
As
Return(
  Select 
   [ProductName] = ProductName
  ,[InventoryDate] = InventoryDate
  ,[InventoryCount] = InventoryCount
  ,[PreviousMonthCount] = PreviousMonthCount
  ,[KPI] = KPI
  From dbo.vProductInventoriesWithPreviousMonthCountsWithKPIs
  Where KPI = @KPI
  );

go

-- Check that it works:
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(1);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(0);
Select * From fProductInventoriesWithPreviousMonthCountsWithKPIs(-1);

go

/***************************************************************************************/