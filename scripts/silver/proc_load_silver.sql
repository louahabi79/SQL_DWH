/*
================================================================================
Stored Procedure: silver.load_silver
Description:
    Loads and transforms data from the Bronze layer into the Silver layer.

Purpose:
    - Clean and standardize raw Bronze data.
    - Handle invalid and missing values.
    - Normalize categorical fields.
    - Remove duplicate customer records.
    - Standardize dates, prices, sales amounts, and identifiers.
    - Provide execution-time logging for each table load.
    - Handle errors without stopping the entire SQL script unexpectedly.

Source Layer:  bronze
Target Layer:  silver
================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    -- Variables used to track execution time for individual tables and the full batch.
    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        PRINT '====================================================';
        PRINT ' LOADING SILVER LAYER';
        PRINT '====================================================';


        /*======================================================================
          CRM TABLES
        ======================================================================*/

        PRINT '----------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '----------------------------------';

        -- Start tracking the total Silver layer loading duration.
        SET @batch_start_time = GETDATE();


        /*----------------------------------------------------------------------
          1. CRM Customer Information
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_cust_info';

        -- Full refresh: remove existing Silver layer data before loading.
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data Into: silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )

        SELECT
            cst_id,
            cst_key,

            -- Remove leading and trailing spaces from customer names.
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,

            -- Standardize marital status codes into readable values.
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,

            -- Standardize gender codes into readable values.
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,

            cst_create_date

        FROM (
            SELECT
                *,

                -- Assign a row number to each customer.
                -- The most recent record is ranked first.
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last

            FROM bronze.crm_cust_info

            -- Ignore records where the customer ID is missing.
            WHERE cst_id IS NOT NULL
        ) t

        -- Keep only the latest record for each customer.
        WHERE flag_last = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + 's';

        PRINT '>> ----------------------------------------';


        /*----------------------------------------------------------------------
          2. CRM Product Information
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_prd_info';

        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data Into: silver.crm_prd_info';

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )

        SELECT
            prd_id,

            -- Convert the category identifier into the Silver layer format.
            REPLACE(
                SUBSTRING(prd_key, 1, 5),
                '-',
                '_'
            ) AS cat_id,

            -- Extract the product key from the source product key.
            SUBSTRING(
                prd_key,
                7,
                LEN(prd_key)
            ) AS prd_key,

            prd_nm,

            -- Replace missing product costs with zero.
            COALESCE(prd_cost, 0) AS prd_cost,

            -- Convert product line codes into descriptive values.
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,

            -- Convert product start dates to the DATE data type.
            CAST(prd_start_dt AS DATE) AS prd_start_dt,

            -- Calculate the end date using the next product start date.
            -- Subtracting one day creates a continuous validity period.
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) - 1
                AS DATE
            ) AS prd_end_dt

        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + 's';

        PRINT '>> ----------------------------------------';


        /*----------------------------------------------------------------------
          3. CRM Sales Details
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_sales_details';

        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data Into: silver.crm_sales_details';

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )

        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            -- Validate and convert order dates from YYYYMMDD format.
            -- Invalid or zero dates are converted to NULL.
            CASE
                WHEN sls_order_dt <= 0
                    OR LEN(sls_order_dt) != 8
                    THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,

            -- Validate and convert shipping dates.
            CASE
                WHEN sls_ship_dt <= 0
                    OR LEN(sls_ship_dt) != 8
                    THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,

            -- Validate and convert due dates.
            CASE
                WHEN sls_due_dt <= 0
                    OR LEN(sls_due_dt) != 8
                    THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,

            -- Recalculate sales when the source value is invalid,
            -- missing, or inconsistent with quantity * price.
            CASE
                WHEN sls_sales <= 0
                    OR sls_sales IS NULL
                    OR sls_sales != sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Ensure the price is positive.
            -- If the price is missing or zero, derive it from sales / quantity.
            -- NULLIF prevents division by zero.
            CASE
                WHEN sls_price = 0
                    OR sls_price IS NULL
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE ABS(sls_price)
            END AS sls_price

        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + 's';

        PRINT '>> ----------------------------------------';


        /*======================================================================
          ERP TABLES
        ======================================================================*/

        PRINT '----------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '----------------------------------';


        /*----------------------------------------------------------------------
          4. ERP Product Category
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';

        -- No major transformation is required for this dataset.
        -- Data is transferred from Bronze to Silver as-is.
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )

        SELECT
            id,
            cat,
            subcat,
            maintenance

        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + 's';

        PRINT '>> ----------------------------------------';


        /*----------------------------------------------------------------------
          5. ERP Location Information
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_loc_a101';

        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data Into: silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )

        SELECT

            -- Remove hyphens from customer IDs to standardize the identifier.
            REPLACE(cid, '-', '') AS cid,

            -- Standardize country names and handle missing values.
            CASE
                WHEN TRIM(cntry) IN ('USA', 'US')
                    THEN 'United States'

                WHEN TRIM(cntry) = 'DE'
                    THEN 'Germany'

                WHEN cntry IS NULL
                    OR TRIM(cntry) = ''
                    THEN 'n/a'

                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + 's';

        PRINT '>> ----------------------------------------';


        /*----------------------------------------------------------------------
          6. ERP Customer Demographics
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_cust_az12';

        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data Into: silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )

        SELECT

            -- Remove the 'NAS' prefix from customer IDs when present.
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            -- Future birth dates are considered invalid and replaced with NULL.
            CASE
                WHEN bdate > GETDATE()
                    THEN NULL
                ELSE bdate
            END AS bdate,

            -- Standardize gender values and handle missing values.
            CASE
                WHEN gen IS NULL
                    OR TRIM(gen) = ''
                    THEN 'n/a'

                WHEN UPPER(TRIM(gen)) = 'M'
                    THEN 'Male'

                WHEN UPPER(TRIM(gen)) = 'F'
                    THEN 'Female'

                ELSE TRIM(gen)
            END AS gen

        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + 's';

        PRINT '>> ----------------------------------------';


        /*======================================================================
          LOAD COMPLETED
        ======================================================================*/

        SET @batch_end_time = GETDATE();

        PRINT '======================================';
        PRINT 'LOADING SILVER LAYER IS COMPLETED!';

        -- Display the total execution time for the complete Silver layer load.
        PRINT '        - Total load duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @batch_start_time,
                    @batch_end_time
                ) AS NVARCHAR
            )
            + 's';

        PRINT '======================================';


    END TRY


    /*======================================================================
      ERROR HANDLING
    ======================================================================*/

    BEGIN CATCH

        PRINT '============================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';

        -- Display useful information for debugging failed loads.
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR);

        PRINT '=============================================';

    END CATCH;

END;
