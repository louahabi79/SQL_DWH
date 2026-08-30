/*
================================================================================
Gold Layer - Dimensional Model
================================================================================

Purpose:
    Create business-ready views in the Gold layer based on the cleaned and
    standardized data available in the Silver layer.

Data Model:
    - gold.dim_customers : Customer dimension
    - gold.dim_products  : Product dimension
    - gold.fact_sales    : Sales fact table

Model Type:
    Star Schema

The Gold layer is designed for:
    - Business intelligence and reporting
    - Analytics and data visualization
    - Simplified access to business entities
    - Consistent surrogate keys for dimensions
================================================================================
*/


/*==============================================================================
  1. CUSTOMER DIMENSION
==============================================================================*/

-- Drop the existing view if it already exists.
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO


CREATE VIEW gold.dim_customers AS

SELECT

    -- Generate a surrogate key for the customer dimension.
    -- This key is used to link customers to the sales fact table.
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,

    -- Business/natural key coming from the CRM source.
    ci.cst_id AS customer_id,

    -- Customer reference number used to connect CRM and ERP data.
    ci.cst_key AS customer_number,

    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,

    -- Customer country from the ERP location dataset.
    la.cntry AS country,

    ci.cst_marital_status AS marital_status,

    -- Use the CRM gender when it is available.
    -- Otherwise, fall back to the ERP customer demographic data.
    CASE
        WHEN ci.cst_gndr != 'n/a'
            THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    -- Customer birth date from the ERP source.
    ca.bdate AS birthdate,

    -- Original customer creation date from CRM.
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info ci

-- Enrich CRM customer information with ERP demographic data.
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

-- Enrich customer information with country/location data.
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;

GO


/*==============================================================================
  2. PRODUCT DIMENSION
==============================================================================*/

-- Drop the existing product dimension view if it already exists.
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO


CREATE VIEW gold.dim_products AS

SELECT

    -- Generate a surrogate key for each product.
    -- The ordering provides a deterministic key assignment within the view.
    ROW_NUMBER() OVER (
        ORDER BY cpi.prd_start_dt, cpi.prd_key
    ) AS product_key,

    -- Product business/natural key.
    cpi.prd_id AS product_id,

    -- Standardized product number.
    cpi.prd_key AS product_number,

    cpi.prd_nm AS product_name,

    -- Category identifier used to join CRM product data
    -- with the ERP product category data.
    cpi.cat_id AS category_id,

    -- Product category information from ERP.
    pcg.cat AS category,
    pcg.subcat AS subcategory,
    pcg.maintenance,

    cpi.prd_cost AS cost,
    cpi.prd_line AS product_line,

    -- Start date of the current product version.
    cpi.prd_start_dt AS start_date

FROM silver.crm_prd_info cpi

-- Enrich CRM product information with ERP category information.
LEFT JOIN silver.erp_px_cat_g1v2 pcg
    ON cpi.cat_id = pcg.id

-- Keep only the current version of each product.
-- Historical product records have a populated end date.
WHERE cpi.prd_end_dt IS NULL;

GO


/*==============================================================================
  3. SALES FACT
==============================================================================*/

-- Drop the existing sales fact view if it already exists.
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO


CREATE VIEW gold.fact_sales AS

SELECT

    -- Sales transaction identifier.
    sls_ord_num AS order_number,

    -- Surrogate product key from the product dimension.
    dp.product_key,

    -- Surrogate customer key from the customer dimension.
    dc.customer_key,

    -- Sales measures used for analytical calculations.
    sls_sales AS sales_amount,
    sls_quantity AS quantity,
    sls_price AS price,

    -- Sales transaction dates.
    sls_order_dt AS order_date,
    sls_ship_dt AS shipping_date,
    sls_due_dt AS due_date

FROM silver.crm_sales_details sd

-- Replace the natural product number with the product dimension key.
LEFT JOIN gold.dim_products dp
    ON sd.sls_prd_key = dp.product_number

-- Replace the natural customer ID with the customer dimension key.
LEFT JOIN gold.dim_customers dc
    ON sd.sls_cust_id = dc.customer_id;

GO
