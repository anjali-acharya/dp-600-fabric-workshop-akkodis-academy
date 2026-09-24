/* ============================================================================
   Exercise 1: Design and Implement a Dimensional Model
   Lab: https://microsoftlearning.github.io/mslearn-fabric/Instructions/Labs/26-design-dimensional-models.html
   Warehouse: ContosoDW
   Run these blocks in order, as separate "New SQL query" statements.
   ============================================================================ */


/* ----------------------------------------------------------------------
   STEP 1: Create the fact table
   Grain: one row per sales transaction line item
   ---------------------------------------------------------------------- */
CREATE TABLE f_Sales
(
    DateKey INT NOT NULL,
    StoreKey INT NOT NULL,
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    SalesAmount DECIMAL(10,2) NOT NULL,
    DiscountAmount DECIMAL(10,2) NOT NULL
);


/* ----------------------------------------------------------------------
   STEP 2: Create the dimension tables
   Date & Customer = simple (Type 1 only)
   Store & Product = include SCD Type 2 tracking columns
   ---------------------------------------------------------------------- */

-- Date dimension: uses YYYYMMDD integer format as surrogate key
CREATE TABLE d_Date
(
    DateKey INT NOT NULL,
    FullDate DATE NOT NULL,
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    [Month] INT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    [Day] INT NOT NULL,
    [DayOfWeek] VARCHAR(10) NOT NULL,
    FiscalYear INT NOT NULL,
    FiscalQuarter INT NOT NULL,
    IsHoliday BIT NOT NULL,
    IsWeekday BIT NOT NULL
);

-- Store dimension: includes SCD Type 2 tracking columns
CREATE TABLE d_Store
(
    StoreKey INT NOT NULL,
    StoreNaturalKey VARCHAR(10) NOT NULL,
    StoreName VARCHAR(50) NOT NULL,
    StoreType VARCHAR(20) NOT NULL,
    City VARCHAR(50) NOT NULL,
    [State] VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Region VARCHAR(50) NOT NULL,
    OpenDate DATE NOT NULL,
    ValidFrom DATE NOT NULL,
    ValidTo DATE NOT NULL,
    IsCurrent BIT NOT NULL
);

-- Product dimension: includes SCD Type 2 tracking columns
CREATE TABLE d_Product
(
    ProductKey INT NOT NULL,
    ProductNaturalKey VARCHAR(10) NOT NULL,
    ProductName VARCHAR(50) NOT NULL,
    Brand VARCHAR(50) NOT NULL,
    Subcategory VARCHAR(50) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    UnitCost DECIMAL(10,2) NOT NULL,
    ValidFrom DATE NOT NULL,
    ValidTo DATE NOT NULL,
    IsCurrent BIT NOT NULL
);

-- Customer dimension: simple structure (SCD Type 1 only)
CREATE TABLE d_Customer
(
    CustomerKey INT NOT NULL,
    CustomerName VARCHAR(50) NOT NULL,
    Segment VARCHAR(20) NOT NULL,
    City VARCHAR(50) NOT NULL,
    [State] VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    LoyaltyTier VARCHAR(20) NOT NULL,
    JoinDate DATE NOT NULL
);


/* ----------------------------------------------------------------------
   STEP 3: Add table constraints (star schema wiring)
   NOTE: Constraints are NOT ENFORCED in Fabric Warehouse - they exist as
   metadata only, mainly so Power BI can auto-detect relationships when
   building a semantic model. Fabric does not validate them at insert time.
   ---------------------------------------------------------------------- */

-- Primary keys on dimension tables
ALTER TABLE d_Date
    ADD CONSTRAINT PK_d_Date PRIMARY KEY NONCLUSTERED (DateKey) NOT ENFORCED;

ALTER TABLE d_Store
    ADD CONSTRAINT PK_d_Store PRIMARY KEY NONCLUSTERED (StoreKey) NOT ENFORCED;

ALTER TABLE d_Product
    ADD CONSTRAINT PK_d_Product PRIMARY KEY NONCLUSTERED (ProductKey) NOT ENFORCED;

ALTER TABLE d_Customer
    ADD CONSTRAINT PK_d_Customer PRIMARY KEY NONCLUSTERED (CustomerKey) NOT ENFORCED;

-- Foreign keys on the fact table
ALTER TABLE f_Sales
    ADD CONSTRAINT FK_Sales_Date FOREIGN KEY (DateKey)
        REFERENCES d_Date(DateKey) NOT ENFORCED;

ALTER TABLE f_Sales
    ADD CONSTRAINT FK_Sales_Store FOREIGN KEY (StoreKey)
        REFERENCES d_Store(StoreKey) NOT ENFORCED;

ALTER TABLE f_Sales
    ADD CONSTRAINT FK_Sales_Product FOREIGN KEY (ProductKey)
        REFERENCES d_Product(ProductKey) NOT ENFORCED;

ALTER TABLE f_Sales
    ADD CONSTRAINT FK_Sales_Customer FOREIGN KEY (CustomerKey)
        REFERENCES d_Customer(CustomerKey) NOT ENFORCED;


/* ----------------------------------------------------------------------
   STEP 4: Load sample data
   ---------------------------------------------------------------------- */

-- Date dimension data
INSERT INTO d_Date VALUES
(20260105, '2026-01-05', 2026, 1, 1, 'January', 5, 'Monday', 2026, 3, 0, 1),
(20260112, '2026-01-12', 2026, 1, 1, 'January', 12, 'Monday', 2026, 3, 0, 1),
(20260209, '2026-02-09', 2026, 1, 2, 'February', 9, 'Monday', 2026, 3, 0, 1),
(20260302, '2026-03-02', 2026, 1, 3, 'March', 2, 'Monday', 2026, 3, 0, 1),
(20260406, '2026-04-06', 2026, 2, 4, 'April', 6, 'Monday', 2026, 4, 0, 1),
(20260504, '2026-05-04', 2026, 2, 5, 'May', 4, 'Monday', 2026, 4, 0, 1);

-- Store dimension data
INSERT INTO d_Store VALUES
(1, 'ST-001', 'Contoso Downtown', 'Flagship', 'Seattle', 'Washington', 'United States', 'West', '2020-03-15', '2026-01-01', '9999-12-31', 1),
(2, 'ST-002', 'Contoso Mall', 'Standard', 'Portland', 'Oregon', 'United States', 'West', '2021-07-01', '2026-01-01', '9999-12-31', 1),
(3, 'ST-003', 'Contoso Central', 'Standard', 'Chicago', 'Illinois', 'United States', 'Central', '2019-11-20', '2026-01-01', '9999-12-31', 1),
(4, 'ST-004', 'Contoso Plaza', 'Express', 'New York', 'New York', 'United States', 'East', '2022-01-10', '2026-01-01', '9999-12-31', 1);

-- Product dimension data
INSERT INTO d_Product VALUES
(1, 'MB-PRO', 'Mountain Bike Pro', 'AdventureWorks', 'Mountain Bikes', 'Bikes', 1200.00, '2026-01-01', '9999-12-31', 1),
(2, 'RB-ELT', 'Road Bike Elite', 'AdventureWorks', 'Road Bikes', 'Bikes', 900.00, '2026-01-01', '9999-12-31', 1),
(3, 'HL-STD', 'Cycling Helmet', 'SafeRide', 'Helmets', 'Accessories', 25.00, '2026-01-01', '9999-12-31', 1),
(4, 'WB-STD', 'Water Bottle', 'HydroGear', 'Bottles', 'Accessories', 5.00, '2026-01-01', '9999-12-31', 1),
(5, 'LK-STD', 'Bike Lock', 'SecureLock', 'Locks', 'Accessories', 15.00, '2026-01-01', '9999-12-31', 1);

-- Customer dimension data
INSERT INTO d_Customer VALUES
(1, 'Jordan Rivera', 'Premium', 'Seattle', 'Washington', 'United States', 'Gold', '2023-06-15'),
(2, 'Alex Chen', 'Standard', 'Portland', 'Oregon', 'United States', 'Silver', '2024-01-20'),
(3, 'Sam Patel', 'Premium', 'Chicago', 'Illinois', 'United States', 'Gold', '2022-11-05'),
(4, 'Taylor Kim', 'Budget', 'New York', 'New York', 'United States', 'Bronze', '2025-03-12'),
(5, 'Morgan Lee', 'Standard', 'Seattle', 'Washington', 'United States', 'Silver', '2024-08-30');

-- Fact data (sales transactions)
INSERT INTO f_Sales VALUES
(20260105, 1, 1, 1, 1, 1500.00, 1500.00, 0.00),
(20260105, 1, 3, 1, 2, 35.00, 70.00, 5.00),
(20260112, 2, 2, 2, 1, 1100.00, 1100.00, 100.00),
(20260112, 2, 4, 2, 3, 8.00, 24.00, 0.00),
(20260209, 3, 1, 3, 2, 1500.00, 3000.00, 150.00),
(20260209, 3, 5, 3, 1, 22.00, 22.00, 0.00),
(20260302, 1, 2, 5, 1, 1100.00, 1100.00, 0.00),
(20260302, 4, 3, 4, 4, 35.00, 140.00, 10.00),
(20260406, 2, 1, 2, 1, 1500.00, 1500.00, 75.00),
(20260504, 3, 4, 3, 5, 8.00, 40.00, 0.00);


/* ----------------------------------------------------------------------
   STEP 5: Query the star schema
   ---------------------------------------------------------------------- */

-- 5a. Sales by product category and month
SELECT
    d.MonthName,
    p.Category,
    SUM(f.SalesAmount) AS TotalSales,
    SUM(f.Quantity) AS TotalQuantity,
    SUM(f.DiscountAmount) AS TotalDiscounts
FROM f_Sales f
JOIN d_Date d ON f.DateKey = d.DateKey
JOIN d_Product p ON f.ProductKey = p.ProductKey
GROUP BY d.MonthName, d.[Month], p.Category
ORDER BY d.[Month], p.Category;

-- 5b. Sales by store region and customer segment
SELECT
    s.Region,
    c.Segment,
    SUM(f.SalesAmount) AS TotalSales,
    COUNT(*) AS TransactionCount
FROM f_Sales f
JOIN d_Store s ON f.StoreKey = s.StoreKey
JOIN d_Customer c ON f.CustomerKey = c.CustomerKey
GROUP BY s.Region, c.Segment
ORDER BY s.Region, c.Segment;


/* ----------------------------------------------------------------------
   STEP 6: Simulate an SCD Type 2 change
   Scenario: Mountain Bike Pro cost increases $1,200 -> $1,350
   effective 2026-03-01
   ---------------------------------------------------------------------- */

-- 6a. Expire the current version of Mountain Bike Pro
UPDATE d_Product
SET ValidTo = '2026-03-01',
    IsCurrent = 0
WHERE ProductNaturalKey = 'MB-PRO'
  AND IsCurrent = 1;

-- 6b. Insert the new version with the updated cost
INSERT INTO d_Product VALUES
(6, 'MB-PRO', 'Mountain Bike Pro', 'AdventureWorks', 'Mountain Bikes', 'Bikes', 1350.00, '2026-03-01', '9999-12-31', 1);

-- 6c. A sale after the cost change references the new product version (ProductKey = 6)
INSERT INTO f_Sales VALUES
(20260504, 1, 6, 5, 1, 1500.00, 1500.00, 0.00);

-- 6d. Verify: each sale keeps the product cost that was in effect at the time
SELECT
    d.FullDate,
    p.ProductName,
    p.UnitCost AS ProductCostVersion,
    p.ValidFrom AS CostEffectiveDate,
    f.Quantity,
    f.SalesAmount
FROM f_Sales f
JOIN d_Date d ON f.DateKey = d.DateKey
JOIN d_Product p ON f.ProductKey = p.ProductKey
WHERE p.ProductNaturalKey = 'MB-PRO'
ORDER BY d.FullDate;


/* ----------------------------------------------------------------------
   STEP 7: Simulate an SCD Type 1 change
   Scenario: correct product name "Water Bottle" -> "Insulated Water Bottle"
   (overwrite, no history kept)
   ---------------------------------------------------------------------- */

-- 7a. Overwrite the product name
UPDATE d_Product
SET ProductName = 'Insulated Water Bottle'
WHERE ProductNaturalKey = 'WB-STD';

-- 7b. Verify both SCD changes together
-- Expect: MB-PRO has 2 rows (Type 2), WB-STD has 1 row with corrected name (Type 1)
SELECT ProductKey, ProductNaturalKey, ProductName, UnitCost, ValidFrom, ValidTo, IsCurrent
FROM d_Product
ORDER BY ProductNaturalKey, ValidFrom;


/* ----------------------------------------------------------------------
   STEP 8: Verify the full design - join all 4 dimensions to the fact table
   ---------------------------------------------------------------------- */
SELECT
    d.FullDate,
    d.[Year],
    d.MonthName,
    s.StoreName,
    s.Region,
    p.ProductName,
    p.Category,
    c.CustomerName,
    c.Segment,
    f.Quantity,
    f.UnitPrice,
    f.SalesAmount,
    f.DiscountAmount
FROM f_Sales f
JOIN d_Date d ON f.DateKey = d.DateKey
JOIN d_Store s ON f.StoreKey = s.StoreKey
JOIN d_Product p ON f.ProductKey = p.ProductKey
JOIN d_Customer c ON f.CustomerKey = c.CustomerKey
ORDER BY d.FullDate, s.StoreName;


/* ============================================================================
   DESIGN SUMMARY (for reference - not executable)
   ----------------------------------------------------------------------------
   Schema type : Star schema - 1 fact table (f_Sales) + 4 dimensions
   Grain       : One row per sales transaction line item
   Measures    : Quantity (additive), UnitPrice (non-additive - avg, not sum),
                 SalesAmount (additive), DiscountAmount (additive)
   Hierarchies : Date (Year > Quarter > Month > Day)
                 Store (Region > Country > State > City)
                 Product (Category > Subcategory > Brand > Product)
   SCD tracking: Type 2 on product cost; Type 1 on product name & customer
                 attributes; store dimension includes Type 2 columns by design
   ============================================================================ */
