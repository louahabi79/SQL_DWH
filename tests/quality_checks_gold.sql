/*
================================================================================
Gold Layer - Quality Checks
================================================================================

Purpose:
    Validate the quality, consistency, and integrity of the Gold layer.

Tables / Views Checked:
    - gold.dim_customers
    - gold.dim_products
    - gold.fact_sales

Quality Areas:
    1. Uniqueness checks
    2. NULL value checks
    3. Duplicate business key checks
    4. Referential integrity checks
    5. Data consistency checks
    6. Date validation
    7. Business rule validation

Expected Result:
    Each query should return ZERO rows unless explicitly stated otherwise.

Note:
    These checks are designed for development and validation purposes.
    They can later be integrated into an automated ETL/data quality pipeline.
================================================================================
*/


/*==============================================================================
  1. CUSTOMER DIMENSION - UNIQUENESS CHECKS
==============================================================================*/

-- Check whether customer surrogate keys are unique.
-- Expected result: ZERO rows.
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- Check whether customer business IDs are unique.
-- Expected result: ZERO rows.
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Check whether customer numbers are unique.
-- Expected result: ZERO rows.
SELECT
    customer_number,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_number
HAVING COUNT(*) > 1;


/*==============================================================================
  2. CUSTOMER DIMENSION - NULL VALUE CHECKS
==============================================================================*/

-- Check for missing customer keys.
-- Expected result: ZERO rows.
SELECT *
FROM gold.dim_customers
WHERE customer_key IS NULL;


-- Check for missing customer IDs.
-- Expected result: ZERO rows.
SELECT *
FROM gold.dim_customers
WHERE customer_id IS NULL;


-- Check for missing customer numbers.
-- Expected result: ZERO rows.
SELECT *
FROM gold.dim_customers
WHERE customer_number IS NULL;


/*==============================================================================
  3. CUSTOMER DIMENSION - ATTRIBUTE VALIDATION
==============================================================================*/

-- Check for unexpected gender values.
-- Expected values: Male, Female, n/a.
SELECT
    gender,
    COUNT(*) AS record_count
FROM gold.dim_customers
GROUP BY gender
ORDER BY record_count DESC;


-- Check for unexpected marital status values.
-- Expected values: Single, Married, n/a.
SELECT
    marital_status,
    COUNT(*) AS record_count
FROM gold.dim_customers
GROUP BY marital_status
ORDER BY record_count DESC;


-- Check for customers with a future birthdate.
-- Expected result: ZERO rows.
SELECT *
FROM gold.dim_customers
WHERE birthdate > GETDATE();


/*==============================================================================
  4. PRODUCT DIMENSION - UNIQUENESS CHECKS
==============================================================================*/

-- Check whether product surrogate keys are unique.
-- Expected result: ZERO rows.
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-- Check whether product IDs are unique.
-- Expected result: ZERO rows.
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Check whether product numbers are unique.
-- Expected result: ZERO rows.
SELECT
    product_number,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;


/*==============================================================================
  5. PRODUCT DIMENSION - NULL VALUE CHECKS
==============================================================================*/

-- Check for missing product keys.
-- Expected result: ZERO rows.
SELECT *
FROM gold.dim_products
WHERE product_key IS NULL;


-- Check for missing product IDs.
-- Expected result: ZERO rows.
SELECT *
FROM gold.dim_products
WHERE product_id IS NULL;


-- Check for missing product numbers.
-- Expected result: ZERO rows.
SELECT *
FROM gold.dim_products
WHERE product_number IS NULL;


/*==============================================================================
  6. PRODUCT DIMENSION - BUSINESS RULE VALIDATION
==============================================================================*/

-- Check for negative product costs.
-- Expected result: ZERO rows.
SELECT *
FROM gold.dim_products
WHERE cost < 0;


-- Check that only current product records exist.
-- Since dim_products filters prd_end_dt IS NULL,
-- the result should always be ZERO rows.
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt IS NULL
  AND prd_key NOT IN (
      SELECT product_number
      FROM gold.dim_products
  );


/*==============================================================================
  7. FACT SALES - NULL VALUE CHECKS
==============================================================================*/

-- Check for missing order numbers.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE order_number IS NULL;


-- Check for missing product foreign keys.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE product_key IS NULL;


-- Check for missing customer foreign keys.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE customer_key IS NULL;


/*==============================================================================
  8. FACT SALES - REFERENTIAL INTEGRITY
==============================================================================*/

-- Check for sales records referencing a non-existing product.
-- Expected result: ZERO rows.
SELECT
    fs.*
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
    ON fs.product_key = dp.product_key
WHERE dp.product_key IS NULL;


-- Check for sales records referencing a non-existing customer.
-- Expected result: ZERO rows.
SELECT
    fs.*
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
    ON fs.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL;


/*==============================================================================
  9. FACT SALES - DUPLICATE CHECKS
==============================================================================*/

-- Check for duplicated sales order lines.
--
-- Note:
-- An order number may legitimately appear multiple times because one order
-- can contain multiple products.
--
-- Therefore, this check identifies duplicate combinations of:
-- order number + product + customer.
--
-- Expected result: ZERO rows.
SELECT
    order_number,
    product_key,
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY
    order_number,
    product_key,
    customer_key
HAVING COUNT(*) > 1;


/*==============================================================================
  10. FACT SALES - MEASURE VALIDATION
==============================================================================*/

-- Check for invalid sales amounts.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE sales_amount < 0;


-- Check for invalid quantities.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE quantity <= 0;


-- Check for invalid prices.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE price <= 0;


-- Validate the relationship between sales amount, quantity, and price.
--
-- Expected result: ZERO rows.
--
-- A small tolerance is used to avoid false positives caused by
-- decimal precision and floating-point calculations.
SELECT *
FROM gold.fact_sales
WHERE ABS(sales_amount - (quantity * price)) > 0.01;


/*==============================================================================
  11. FACT SALES - DATE VALIDATION
==============================================================================*/

-- Check for sales records with an order date in the future.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE order_date > GETDATE();


-- Check that shipping date is not earlier than order date.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE shipping_date < order_date;


-- Check that due date is not earlier than order date.
-- Expected result: ZERO rows.
SELECT *
FROM gold.fact_sales
WHERE due_date < order_date;


/*==============================================================================
  12. CROSS-DIMENSION CONSISTENCY CHECKS
==============================================================================*/

-- Verify that every product referenced by the fact table exists
-- in the product dimension.
-- Expected result: ZERO rows.
SELECT DISTINCT
    product_key
FROM gold.fact_sales
WHERE product_key NOT IN (
    SELECT product_key
    FROM gold.dim_products
);


-- Verify that every customer referenced by the fact table exists
-- in the customer dimension.
-- Expected result: ZERO rows.
SELECT DISTINCT
    customer_key
FROM gold.fact_sales
WHERE customer_key NOT IN (
    SELECT customer_key
    FROM gold.dim_customers
);


/*==============================================================================
  13. BASIC DATA COMPLETENESS CHECK
==============================================================================*/

-- Compare the number of records between the Silver source
-- and the Gold fact view.
--
-- The counts should normally match unless intentional filtering
-- or transformation is applied.
SELECT
    'Silver Sales' AS table_name,
    COUNT(*) AS record_count
FROM silver.crm_sales_details

UNION ALL

SELECT
    'Gold Sales' AS table_name,
    COUNT(*) AS record_count
FROM gold.fact_sales;


/*==============================================================================
  14. GOLD LAYER SUMMARY
==============================================================================*/

-- Provide a high-level overview of the Gold layer.
SELECT
    'Customers' AS entity,
    COUNT(*) AS record_count
FROM gold.dim_customers

UNION ALL

SELECT
    'Products',
    COUNT(*)
FROM gold.dim_products

UNION ALL

SELECT
    'Sales',
    COUNT(*)
FROM gold.fact_sales;


/*==============================================================================
  END OF GOLD LAYER QUALITY CHECKS
==============================================================================*/
