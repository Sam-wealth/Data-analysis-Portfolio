use SAM_Portfolio_building
SELECT *
FROM Online_Retail

SELECT COUNT(*) AS total_rows
FROM Online_Retail

--to know how many columns are there in the table 
SELECT COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Online_Retail'

SELECT 
    InvoiceDate,
    CAST(InvoiceDate AS DATE) AS InvoiceDateOnly,
    CAST(InvoiceDate AS TIME) AS InvoiceTimeOnly
FROM Online_Retail;

-- 1. Add the new columns
ALTER TABLE Online_Retail
ADD InvoiceDateOnly DATE,
    InvoiceTimeOnly TIME;

-- 2. Populate the new columns with data from the original
UPDATE Online_Retail
SET InvoiceDateOnly = CAST(InvoiceDate AS DATE),
    InvoiceTimeOnly = CAST(InvoiceDate AS TIME);

--to delete column from a table 
ALTER TABLE Online_Retail
DROP COLUMN InvoiceDate

SELECT  CustomerID, StockCode, Description, Country
FROM Online_Retail
WHERE Country = 'United Kingdom'

--to know how many customers came from UK without repeating their orders
SELECT COUNT(DISTINCT CustomerID) AS UniqueUKCustomers
FROM Online_Retail
WHERE Country = 'United Kingdom'

--to know where customerID is NULL for data accuracy 
SELECT *
FROM Online_Retail
WHERE CustomerID is NULL

SELECT * 
FROM Online_Retail
ORDER BY InvoiceNo ASC

--Look for pairs that show up together most times; without repetitions?
SELECT TOP 50 
    a.Description AS Item_A, 
    b.Description AS Item_B, 
    COUNT(*) AS Times_Bought_Together
FROM Online_Retail a
JOIN Online_Retail b ON a.InvoiceNo = b.InvoiceNo
WHERE a.Description < b.Description  -- Avoids pairing an item with itself and prevents double-counting (A,B and B,A)
GROUP BY a.Description, b.Description
ORDER BY Times_Bought_Together DESC;

SELECT TOP 20 
    a.Description AS Item_A, 
    b.Description AS Item_B, 
    COUNT(*) AS Times_Bought_Together
FROM Online_Retail a
JOIN Online_Retail b ON a.InvoiceNo = b.InvoiceNo
WHERE a.Country = 'United Kingdom' 
  AND b.Country = 'United Kingdom'
  AND a.Description < b.Description -- Avoids duplicates and self-pairing
GROUP BY a.Description, b.Description
ORDER BY Times_Bought_Together DESC;

--DATA CLEANING:
--1. Use TRIM to remove accidental spaces and UPPER to make everything uppercase.
UPDATE Online_Retail
SET Description = UPPER(TRIM(Description));

--2. Creating a Products Reference Table is a hallmark of a professional data analyst. 
--It moves your project from a simple "flat file" into a Relational Database structure, which is much more efficient and scalable. 
--STEP 1
--To pick one "official" name for each code.
-- This creates a temporary view of unique StockCodes and their most common Description
SELECT StockCode, MAX(Description) AS OfficialDescription
INTO #UniqueProducts
FROM Online_Retail
WHERE Description IS NOT NULL
GROUP BY StockCode;

--STEP 2: Create the Permanent Products Table
CREATE TABLE Products (
    StockCode NVARCHAR(50) PRIMARY KEY,
    Description NVARCHAR(255)
);
-- Move the unique data into your new table
INSERT INTO Products (StockCode, Description)
SELECT StockCode, OfficialDescription FROM #UniqueProducts;

--STEP 3: CLEAN THE MAIN TABLE USING REFERENCE TABLE 
UPDATE ORT
SET ORT.Description = P.Description
FROM Online_Retail ORT
JOIN Products P ON ORT.StockCode = P.StockCode;

--STEP 4: FINAL VERIFICATION: To make sure each stockcode now have a unique product name
SELECT StockCode, COUNT(DISTINCT Description)
FROM Online_Retail
GROUP BY StockCode
HAVING COUNT(DISTINCT Description) > 1;

SELECT StockCode, Description
FROM Products
WHERE StockCode = '85150'

--To Find Duplicates using the 'Common Table Expression' option
WITH CTE AS (
    SELECT *, 
    ROW_NUMBER() OVER (
        PARTITION BY InvoiceNo, StockCode, Quantity, InvoiceDateOnly, CustomerID 
        ORDER BY InvoiceNo) as row_num
    FROM Online_Retail
)
SELECT * FROM CTE WHERE row_num > 1;

--TO VERIFY that there's no duplicate (in this case using the stockcode)
SELECT StockCode, COUNT(DISTINCT Description) as NameCount
FROM Online_Retail
GROUP BY StockCode
HAVING COUNT(DISTINCT Description) > 1;

SELECT * 
FROM Online_Retail;

SELECT *
FROM #UniqueProducts

--it means what's in prodcuts is exactly what we have in Unique Products
SELECT * 
FROM Products



SELECT * FROM OnlineRetail;
--GETTING THE DATA SHAPE
-- Total line items
SELECT COUNT(*) FROM OnlineRetail;
-- => 541,909

-- How many orders
SELECT COUNT(DISTINCT InvoiceNo) FROM OnlineRetail;
-- => 25,900

-- How many products
SELECT COUNT(DISTINCT StockCode) FROM OnlineRetail;
-- => 3,958

--OBVIOUS PROBLEMS
-- 1. Missing CustomerID 
SELECT COUNT(*) FROM OnlineRetail WHERE CustomerID IS NULL;
-- => 135,080 (~25% of rows)

-- 2. Missing Description
SELECT COUNT(*) FROM OnlineRetail WHERE Description IS NULL;
-- => 1,454

-- 3. Cancelled invoices mixed in
SELECT COUNT(*) as Cancelled_Invoices FROM OnlineRetail WHERE InvoiceNo LIKE 'C%';
-- => 9,288

-- 4. Negative quantities (returns/cancellations)
SELECT COUNT(*) as Returned_Cancelled FROM OnlineRetail WHERE Quantity < 0;
-- => 10,624

-- 5. Zero or negative UnitPrice
SELECT COUNT(*) FROM OnlineRetail WHERE UnitPrice <= 0;
-- => 2,517

-- 6. Non-product StockCodes (fees, postage, charges)
SELECT StockCode, COUNT(*) AS rows
FROM OnlineRetail
WHERE ISNUMERIC(stockcode) = 0
GROUP BY StockCode
ORDER BY rows DESC;
-- => POST(1256), DOT(710), M(571), C2(144), D(77), S(63), BANK CHARGES(37)...

-- StockCodes that contain both letters
SELECT DISTINCT StockCode as ONlyletters_stockcodes
FROM OnlineRetail
WHERE StockCode NOT LIKE '%[0-9]%'   -- has only letters

SELECT COUNT(DISTINCT StockCode) as ONlyletters_stockcodes
FROM OnlineRetail
WHERE StockCode NOT LIKE '%[0-9]%'  

--numbers of stockcodes with both letters and numbers
SELECT COUNT(DISTINCT stockcode)
FROM OnlineRetail 
WHERE StockCode LIKE '%[A-Za-z]%'
    AND StockCode LIKE '%[0-9]%'

--DATA PROFILING
-- Product pairs that appear together most frequently in the same invoice
SELECT 
    a.StockCode        AS product_a,
    a.Description      AS description_a,
    b.StockCode        AS product_b,
    b.Description      AS description_b,
    COUNT(*)           AS times_bought_together
FROM OnlineRetail a
JOIN OnlineRetail b 
    ON a.InvoiceNo = b.InvoiceNo        -- same invoice
    AND a.StockCode < b.StockCode       -- avoid duplicates and self-pairs
WHERE a.StockCode NOT LIKE '%[0-9]%'  -- exclude junk codes
  AND b.StockCode NOT LIKE '%[0-9]%'
    AND a.InvoiceNo NOT LIKE 'C%'        -- exclude cancellations
    AND b.InvoiceNo NOT LIKE 'C%'
GROUP BY 
    a.StockCode, a.Description,
    b.StockCode, b.Description
ORDER BY times_bought_together DESC;

--==NOW CLEANING
--1. Product Names mean the same thing every time — one StockCode = one Description
-- StockCodes that have more than one distinct Description
SELECT 
    StockCode,
    COUNT(DISTINCT Description) AS description_count,
    MIN(Description)            AS description_1,
    MAX(Description)            AS description_2
FROM OnlineRetail
GROUP BY StockCode
HAVING COUNT(DISTINCT Description) > 1
ORDER BY description_count DESC;


-- Rows where every column is identical
SELECT 
    InvoiceNo, StockCode, Description, 
    Quantity, InvoiceDate, UnitPrice, CustomerID, Country,
    COUNT(*) AS duplicate_count
FROM OnlineRetail
GROUP BY 
    InvoiceNo, StockCode, Description, 
    Quantity, InvoiceDate, UnitPrice, CustomerID, Country
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 1: Find the most used description per StockCode
WITH ranked AS (
    SELECT 
        StockCode,
        Description,
        COUNT(*) AS times_used,
        ROW_NUMBER() OVER (
            PARTITION BY StockCode 
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM OnlineRetail
    WHERE Description IS NOT NULL
    GROUP BY StockCode, Description
)
SELECT StockCode, Description AS canonical_description
FROM ranked
WHERE rn = 1;

-- Step 1 — Create the canonical description lookup table
SELECT 
    StockCode,
    Description AS canonical_description
INTO product_lookup
FROM (
    SELECT 
        StockCode,
        Description,
        COUNT(*) AS times_used,
        ROW_NUMBER() OVER (
            PARTITION BY StockCode 
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM OnlineRetail
    WHERE Description IS NOT NULL
    GROUP BY StockCode, Description
) ranked
WHERE rn = 1;

-- Step 2 — Verify it looks right
SELECT TOP 10 * FROM product_lookup
ORDER BY StockCode;

-- Step 3 Create the clean dataset joining back the canonical names
SELECT 
    o.InvoiceNo,
    o.StockCode,
    p.canonical_description   AS Description,
    o.Quantity,
    o.InvoiceDate,
    o.UnitPrice,
    o.CustomerID,
    o.Country
INTO OnlineRetail_clean
FROM OnlineRetail o
LEFT JOIN product_lookup p ON o.StockCode = p.StockCode
WHERE o.InvoiceNo NOT LIKE 'C%'        -- remove cancellations
  AND o.Quantity > 0                    -- remove negative quantities
  AND o.UnitPrice > 0                   -- remove zero price rows
  AND o.StockCode LIKE '%[0-9]%';       -- remove letters-only stockcodes (POST, DOT, M etc)

--Step 4 — Verify the clean table
-- Compare raw vs clean row counts
SELECT 'Raw'   AS dataset, COUNT(*) AS rows FROM OnlineRetail
UNION ALL
SELECT 'Clean' AS dataset, COUNT(*) AS rows FROM OnlineRetail_clean;

--here is the breakdown what was removed 
-- See exactly what was removed and why
SELECT 'Cancellations'        AS reason, COUNT(*) AS rows 
FROM OnlineRetail 
WHERE InvoiceNo LIKE 'C%'

UNION ALL

SELECT 'Negative Quantity'    AS reason, COUNT(*) AS rows 
FROM OnlineRetail 
WHERE Quantity <= 0 
  AND InvoiceNo NOT LIKE 'C%'

UNION ALL

SELECT 'Zero/Negative Price'  AS reason, COUNT(*) AS rows 
FROM OnlineRetail 
WHERE UnitPrice <= 0 
  AND Quantity > 0 
  AND InvoiceNo NOT LIKE 'C%'

UNION ALL

SELECT 'Letters-only StockCode' AS reason, COUNT(*) AS rows 
FROM OnlineRetail 
WHERE StockCode NOT LIKE '%[0-9]%'
  AND InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0;


  --ANALYZING THE DATA:
  -- 1. Product pairs that appear together most frequently in the same invoice
SELECT
    a.StockCode                     AS product_a,
    a.Description                   AS description_a,
    b.StockCode                     AS product_b,
    b.Description                   AS description_b,
    COUNT(*)                        AS times_bought_together
FROM OnlineRetail_clean a
JOIN OnlineRetail_clean b 
    ON  a.InvoiceNo  = b.InvoiceNo      -- same invoice
    AND a.StockCode  < b.StockCode      -- avoid duplicates and self-pairs
GROUP BY 
    a.StockCode, a.Description,
    b.StockCode, b.Description
ORDER BY times_bought_together DESC;


--2 -- Product pairs with count + confidence score
WITH pair_counts AS (
    SELECT 
        a.StockCode                 AS product_a,
        a.Description               AS description_a,
        b.StockCode                 AS product_b,
        b.Description               AS description_b,
        COUNT(*)                    AS times_bought_together
    FROM OnlineRetail_clean a
    JOIN OnlineRetail_clean b 
        ON  a.InvoiceNo = b.InvoiceNo
        AND a.StockCode < b.StockCode
    GROUP BY 
        a.StockCode, a.Description,
        b.StockCode, b.Description
),
product_counts AS (
    SELECT 
        StockCode,
        COUNT(DISTINCT InvoiceNo)   AS total_orders
    FROM OnlineRetail_clean
    GROUP BY StockCode
)
SELECT 
    p.product_a,
    p.description_a,
    p.product_b,
    p.description_b,
    p.times_bought_together,
    pc.total_orders                 AS product_a_total_orders,
    ROUND(
        100.0 * p.times_bought_together / pc.total_orders, 2
    )                               AS confidence_pct
FROM pair_counts p
JOIN product_counts pc ON pc.StockCode = p.product_a
ORDER BY times_bought_together DESC;


-- Clean confidence score + filter strong pairs only
WITH pair_counts AS (
    SELECT 
        a.StockCode                 AS product_a,
        a.Description               AS description_a,
        b.StockCode                 AS product_b,
        b.Description               AS description_b,
        COUNT(*)                    AS times_bought_together
    FROM OnlineRetail_clean a
    JOIN OnlineRetail_clean b 
        ON  a.InvoiceNo = b.InvoiceNo
        AND a.StockCode < b.StockCode
    GROUP BY 
        a.StockCode, a.Description,
        b.StockCode, b.Description
),
product_counts AS (
    SELECT 
        StockCode,
        COUNT(DISTINCT InvoiceNo)   AS total_orders
    FROM OnlineRetail_clean
    GROUP BY StockCode
)
SELECT TOP 50
    p.product_a,
    p.description_a,
    p.product_b,
    p.description_b,
    p.times_bought_together,
    pc.total_orders                 AS product_a_total_orders,
    CAST(ROUND(
        100.0 * p.times_bought_together / pc.total_orders, 2
    ) AS DECIMAL(10,2))             AS confidence_pct
FROM pair_counts p
JOIN product_counts pc ON pc.StockCode = p.product_a
WHERE pc.total_orders >= 100       -- product A must have sold in at least 100 orders
  AND p.times_bought_together >= 50 -- pair must have occurred at least 50 times
  AND 100.0 * p.times_bought_together / pc.total_orders >= 50
ORDER BY confidence_pct DESC;

SELECT *
FROM OnlineRetail_clean