# SQL Data Warehouse (SQL_DWH)

A complete SQL Server-based data warehouse implementation demonstrating the **medallion architecture** (Bronze-Silver-Gold layers) for enterprise data integration, transformation, and analytics.

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Database Setup](#database-setup)
- [How to Run](#how-to-run)
- [Available Scripts/Commands](#available-scriptscommands)
- [Data Architecture](#data-architecture)
- [Database Schema](#database-schema)
- [Testing & Quality Checks](#testing--quality-checks)
- [Medallion Architecture Explanation](#medallion-architecture-explanation)
- [Contributing](#contributing)

## Project Overview

This project implements a complete data warehouse using the **medallion (layered) architecture** pattern. It demonstrates best practices for:

- **Data Integration**: Loading raw data from multiple source systems (CRM and ERP)
- **Data Cleaning & Transformation**: Standardizing and enriching data in the Silver layer
- **Business Analytics**: Providing clean, dimensional data in the Gold layer
- **Data Quality**: Automated validation checks at each layer
- **Performance & Maintainability**: Efficient stored procedures and views

### Use Case

The warehouse integrates customer, product, and sales data from two source systems:
- **CRM System**: Customer and product information with transactional sales data
- **ERP System**: Customer demographics, location, and product categorization

## Features

✅ **Medallion Architecture**
- Bronze Layer: Raw data ingestion from source systems
- Silver Layer: Cleaned, standardized, and deduplicated data
- Gold Layer: Business-ready dimensional model (star schema)

✅ **Automated ETL**
- Stored procedures for each layer with comprehensive error handling
- Data validation and transformation logic
- Load duration tracking and logging

✅ **Data Quality Framework**
- Uniqueness and referential integrity checks
- NULL value and duplicate detection
- Business rule validation
- Data consistency verification

✅ **Star Schema Design**
- Customer dimension with enriched attributes
- Product dimension with categorization
- Sales fact table with comprehensive measures
- Surrogate keys for data warehouse integrity

✅ **Multi-Source Integration**
- CRM data: Customers, products, sales transactions
- ERP data: Customer demographics, locations, product categories
- Intelligent data reconciliation and joining

✅ **Data Standardization**
- Categorical value mapping (e.g., gender, marital status, product lines)
- Date format validation and conversion
- Trim whitespace and handle missing values
- Deduplication with latest-record-wins logic

## Tech Stack

- **Database Engine**: Microsoft SQL Server (T-SQL)
- **Architecture Pattern**: Medallion Architecture (Bronze-Silver-Gold)
- **Data Model**: Star Schema
- **Integration Method**: BULK INSERT from CSV files
- **Version Control**: Git/GitHub

## Project Structure

```
SQL_DWH/
├── scripts/                          # All SQL scripts organized by layer
│   ├── init_database.sql            # Creates database and schemas
│   ├── bronze/
│   │   ├── ddl_bronze.sql           # Create raw Bronze layer tables
│   │   └── proc_load_bronze.sql     # Load raw data from CSV files
│   ├── silver/
│   │   ├── ddl_silver.sql           # Create cleaned Silver layer tables
│   │   └── proc_load_silver.sql     # Transform Bronze → Silver
│   └── gold/
│       └── ddl_gold.sql             # Create dimensional Gold layer views
├── tests/
│   ├── quality_checks_silver.sql    # Validation for Silver layer
│   └── quality_checks_gold.sql      # Validation for Gold layer
├── docs/
│   ├── data_architecture.png        # System architecture diagram
│   ├── data_flow.png                # ETL data flow diagram
│   ├── data_integration.png         # Data integration diagram
│   ├── data_model.png               # Star schema diagram
│   ├── Data_Flow_Diagram.drawio     # Editable flow diagram
│   ├── Data_Model.drawio            # Editable model diagram
│   ├── Integration_model.drawio     # Editable integration diagram
│   └── data_architecture.drawio     # Editable architecture diagram
├── datasets/                        # Source data directory (user-provided CSVs)
│   ├── source_crm/
│   │   ├── cust_info.csv           # Customer master data
│   │   ├── prd_info.csv            # Product master data
│   │   └── sales_details.csv       # Sales transactions
│   └── source_erp/
│       ├── CUST_AZ12.csv           # Customer demographics
│       ├── LOC_A101.csv            # Customer locations
│       └── PX_CAT_G1V2.csv         # Product categories
└── README.md                        # This file
```

## Prerequisites

### Software Requirements

- **SQL Server 2016 or later** (SQL Server Express, Standard, or Enterprise)
  - Download: https://www.microsoft.com/sql-server/sql-server-downloads
- **SQL Server Management Studio (SSMS)** or any compatible SQL editor
  - Download: https://learn.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms
- **Git** (for version control)
  - Download: https://git-scm.com

### Source Data Requirements

The project requires 6 CSV files from your source systems:

**CRM System Files** (place in `datasets/source_crm/`):
- `cust_info.csv` - Customer master data
- `prd_info.csv` - Product information
- `sales_details.csv` - Sales transactions

**ERP System Files** (place in `datasets/source_erp/`):
- `CUST_AZ12.csv` - Customer demographics
- `LOC_A101.csv` - Customer location/country
- `PX_CAT_G1V2.csv` - Product categories

### System Permissions

- Local administrator access to create databases
- File system permissions to access CSV files
- SQL Server service running

## Installation

### Step 1: Clone or Download the Repository

```bash
git clone https://github.com/louahabi79/SQL_DWH.git
cd SQL_DWH
```

### Step 2: Prepare Source Data

1. Create the required directory structure:
```
datasets/
├── source_crm/
└── source_erp/
```

2. Place your CSV files in the appropriate directories:
   - CRM files in `datasets/source_crm/`
   - ERP files in `datasets/source_erp/`

3. **Important**: Update the hardcoded file paths in `scripts/bronze/proc_load_bronze.sql`:
   - Find the lines with `BULK INSERT` statements
   - Replace paths like `C:\Users\Abdenour\Documents\...` with your actual paths
   - Example:
     ```sql
     BULK INSERT bronze.crm_cust_info
     FROM 'C:\Path\To\Your\datasets\source_crm\cust_info.csv'
     ```

### Step 3: Verify SQL Server Connection

1. Open **SQL Server Management Studio (SSMS)**
2. Connect to your SQL Server instance
3. Verify you can access the server (use Windows or SQL Authentication)

## Database Setup

### Step 1: Create Database and Schemas

Execute the initialization script in SSMS:

```sql
-- Open scripts/init_database.sql and run it
-- This will:
-- 1. Drop the DataWareHouse database if it exists
-- 2. Create a new DataWareHouse database
-- 3. Create three schemas: bronze, silver, gold
```

### Step 2: Create Bronze Layer Tables

Execute the Bronze DDL script:

```sql
-- Open scripts/bronze/ddl_bronze.sql and run it
-- This creates 6 raw data tables for CRM and ERP sources
```

### Step 3: Create Silver Layer Tables

Execute the Silver DDL script:

```sql
-- Open scripts/silver/ddl_silver.sql and run it
-- This creates 6 cleaned and standardized tables
```

### Step 4: Create Gold Layer Views

Execute the Gold DDL script:

```sql
-- Open scripts/gold/ddl_gold.sql and run it
-- This creates 3 dimensional views:
-- - gold.dim_customers (customer dimension)
-- - gold.dim_products (product dimension)
-- - gold.fact_sales (sales fact table)
```

## How to Run

### Complete ETL Pipeline (Recommended)

Run the complete data warehouse pipeline in this order:

**1. Initialize Database:**
```sql
-- Execute: scripts/init_database.sql
```

**2. Create All Layer Schemas:**
```sql
-- Execute: scripts/bronze/ddl_bronze.sql
-- Execute: scripts/silver/ddl_silver.sql
-- Execute: scripts/gold/ddl_gold.sql
```

**3. Load Data Through Pipeline:**
```sql
-- Load Bronze layer from CSV files
EXEC bronze.load_bronze;

-- Transform and load Silver layer
EXEC silver.load_silver;

-- Gold layer views are created automatically from Silver data
-- (No load procedure needed for views)
```

### Individual Layer Operations

**Load/Reload Bronze Layer Only:**
```sql
EXEC bronze.load_bronze;
```

**Load/Reload Silver Layer Only (requires Bronze to be populated):**
```sql
EXEC silver.load_silver;
```

**Query the Business-Ready Gold Layer:**
```sql
-- View customer dimension with all attributes
SELECT * FROM gold.dim_customers;

-- View product dimension with categories
SELECT * FROM gold.dim_products;

-- View sales fact table
SELECT * FROM gold.fact_sales;

-- Example: Sales by customer
SELECT 
    dc.customer_number,
    dc.first_name,
    dc.last_name,
    COUNT(*) AS order_count,
    SUM(fs.sales_amount) AS total_sales
FROM gold.fact_sales fs
JOIN gold.dim_customers dc ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_number, dc.first_name, dc.last_name
ORDER BY total_sales DESC;
```

## Available Scripts/Commands

### Setup & Initialization

| Script | Purpose |
|--------|---------|
| `scripts/init_database.sql` | Drop and recreate the DataWareHouse database with schemas |
| `scripts/bronze/ddl_bronze.sql` | Create Bronze raw data tables |
| `scripts/silver/ddl_silver.sql` | Create Silver cleaned data tables |
| `scripts/gold/ddl_gold.sql` | Create Gold dimensional views |

### Data Loading

| Stored Procedure | Purpose | Command |
|------------------|---------|---------|
| `bronze.load_bronze` | Load raw data from CSV files | `EXEC bronze.load_bronze;` |
| `silver.load_silver` | Transform Bronze → Silver | `EXEC silver.load_silver;` |

### Quality Validation

| Script | Purpose | Command |
|--------|---------|---------|
| `tests/quality_checks_silver.sql` | Validate Silver layer | Run all checks to verify data quality |
| `tests/quality_checks_gold.sql` | Validate Gold layer | Run all checks to verify dimensions and facts |

## Data Architecture

### Medallion Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
│            (CRM System)         |          (ERP System)          │
│     - Customers                 |     - Demographics             │
│     - Products                  |     - Locations                │
│     - Sales Transactions        |     - Product Categories       │
└──────────┬──────────────────────┼──────────────────────┬─────────┘
           │                      │                      │
           └──────────────────────┼──────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   BRONZE LAYER (Raw)      │
                    ├───────────────────────────┤
                    │ - crm_cust_info          │
                    │ - crm_prd_info           │
                    │ - crm_sales_details      │
                    │ - erp_cust_az12          │
                    │ - erp_loc_a101           │
                    │ - erp_px_cat_g1v2        │
                    │                           │
                    │ Load Time: ~1-5 seconds  │
                    └────────────┬──────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │  SILVER LAYER (Cleaned)   │
                    ├───────────────────────────┤
                    │ - crm_cust_info (dedup)  │
                    │ - crm_prd_info (keyed)   │
                    │ - crm_sales_details      │
                    │ - erp_cust_az12          │
                    │ - erp_loc_a101           │
                    │ - erp_px_cat_g1v2        │
                    │                           │
                    │ Transformations:          │
                    │ ✓ Data standardization   │
                    │ ✓ Type conversion        │
                    │ ✓ Deduplication          │
                    │ ✓ Data validation        │
                    │ ✓ Null handling          │
                    └────────────┬──────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │   GOLD LAYER (Analytics)  │
                    ├───────────────────────────┤
                    │ Views (Star Schema):      │
                    │ - dim_customers          │
                    │ - dim_products           │
                    │ - fact_sales             │
                    │                           │
                    │ Ready for:                │
                    │ ✓ BI & Reporting         │
                    │ ✓ Analytics              │
                    │ ✓ Dashboards             │
                    │ ✓ Ad-hoc Queries         │
                    └───────────────────────────┘
```

## Database Schema

### Bronze Layer (Raw Data)

Raw data copied as-is from source systems with minimal validation.

**Tables:**
- `bronze.crm_cust_info` - CRM customer master
- `bronze.crm_prd_info` - CRM product master
- `bronze.crm_sales_details` - CRM sales transactions
- `bronze.erp_cust_az12` - ERP customer demographics
- `bronze.erp_loc_a101` - ERP customer locations
- `bronze.erp_px_cat_g1v2` - ERP product categories

### Silver Layer (Cleaned & Standardized)

Cleaned, validated, and enriched data ready for consumption.

**Tables:**
- `silver.crm_cust_info` - Deduplicated customers
- `silver.crm_prd_info` - Standardized products with calculated end dates
- `silver.crm_sales_details` - Validated sales transactions
- `silver.erp_cust_az12` - Standardized demographics
- `silver.erp_loc_a101` - Standardized locations
- `silver.erp_px_cat_g1v2` - Standardized categories

**Key Transformations:**
- Trim whitespace from string fields
- Standardize categorical values (M→Male, F→Female, S→Single, M→Married)
- Convert dates from YYYYMMDD integers to DATE type
- Remove/normalize hyphens in identifiers
- Calculate product effective dating
- Recalculate invalid sales amounts (quantity × price)
- Deduplicate customer records (keep latest)

### Gold Layer (Dimensional Model - Star Schema)

Business-ready dimensional views optimized for analytics.

#### Customer Dimension (`gold.dim_customers`)
```
customer_key          - Surrogate key
customer_id           - Business key (from CRM)
customer_number       - Customer reference number
first_name            - From CRM
last_name             - From CRM
country               - From ERP locations
marital_status        - From CRM
gender                - From CRM or ERP (CRM preferred)
birthdate             - From ERP
create_date           - From CRM
```

#### Product Dimension (`gold.dim_products`)
```
product_key           - Surrogate key
product_id            - Business key (from CRM)
product_number        - Product reference
product_name          - From CRM
category_id           - Used to join with ERP
category              - From ERP categories
subcategory           - From ERP categories
maintenance           - From ERP categories
cost                  - From CRM
product_line          - From CRM (Mountain, Road, Touring, Other Sales)
start_date            - Product version effective date
```

#### Sales Fact Table (`gold.fact_sales`)
```
order_number          - Transaction identifier
product_key           - FK to dim_products
customer_key          - FK to dim_customers
sales_amount          - Sales measure
quantity              - Quantity measure
price                 - Unit price measure
order_date            - Transaction date
shipping_date         - Shipping date
due_date              - Due date
```

## Testing & Quality Checks

### Silver Layer Quality Checks

Run `tests/quality_checks_silver.sql` to validate:

✓ **Primary Key Integrity**
- No NULL or duplicate customer IDs
- No NULL or duplicate product IDs

✓ **Data Standardization**
- No unwanted leading/trailing spaces
- Gender values standardized (Male, Female, n/a)
- Marital status standardized (Single, Married, n/a)
- Product line values standardized (Mountain, Road, Touring, Other Sales, n/a)

✓ **Data Consistency**
- Sales = Quantity × Price
- All monetary values positive
- All quantities positive

✓ **Date Validation**
- No invalid date formats
- Order date ≤ Shipping date ≤ Due date
- Birth dates in reasonable range (1924-present)
- Product start date ≤ Product end date

✓ **Country Standardization**
- Country codes standardized (USA→United States, DE→Germany, etc.)

### Gold Layer Quality Checks

Run `tests/quality_checks_gold.sql` to validate:

✓ **Dimensional Integrity**
- Surrogate key uniqueness
- Business key uniqueness
- No NULL critical keys

✓ **Fact Table Validation**
- No orphaned foreign keys (referential integrity)
- No duplicate sales transactions
- Sales amount consistency with quantity × price
- Date sequence validation

✓ **Cross-Dimensional Consistency**
- All products in fact table exist in dimension
- All customers in fact table exist in dimension
- Record count consistency between layers

✓ **Business Rule Validation**
- No negative costs
- No invalid genders/marital statuses
- Current products only (end date IS NULL)
- All dates within valid ranges

## Medallion Architecture Explanation

### Why Medallion Architecture?

The medallion pattern provides:

1. **Separation of Concerns**
   - Bronze: Extract (raw data ingestion)
   - Silver: Transform (data cleaning and standardization)
   - Gold: Load (business-ready output)

2. **Data Quality Control**
   - Quality improves at each layer
   - Issues isolated and tracked at source
   - Audit trail of transformations

3. **Reusability**
   - Bronze tables reused by multiple transformations
   - Silver tables reused for multiple reports
   - Standardized business metrics in Gold

4. **Scalability**
   - Easy to add new source systems (Bronze)
   - Transformations can be enhanced independently
   - New reports use existing Gold data

5. **Maintainability**
   - Clear data lineage
   - Simple rollback if issues discovered
   - Documentation of transformation logic

### Data Flow Through Layers

```
RAW DATA (CSV Files)
        ↓
    BRONZE LAYER
    ┌─────────────────────────────┐
    │ Load raw data as-is         │
    │ Minimal validation          │
    │ Source-aligned structure    │
    └────────────┬────────────────┘
                 ↓
    SILVER LAYER
    ┌─────────────────────────────┐
    │ Clean & standardize         │
    │ Handle nulls & invalids     │
    │ Deduplicate records         │
    │ Type conversions            │
    │ Business rules applied      │
    └────────────┬────────────────┘
                 ↓
    GOLD LAYER
    ┌─────────────────────────────┐
    │ Create dimensional model    │
    │ Build surrogate keys        │
    │ Join dimensions             │
    │ Create fact tables          │
    │ Business-ready views        │
    └─────────────────────────────┘
                 ↓
    ANALYTICS & REPORTING
```

## Typical Usage Workflows

### Workflow 1: Initial Setup

```sql
-- 1. Create database and schemas
EXECUTE scripts/init_database.sql

-- 2. Create Bronze tables
EXECUTE scripts/bronze/ddl_bronze.sql

-- 3. Create Silver tables
EXECUTE scripts/silver/ddl_silver.sql

-- 4. Create Gold views
EXECUTE scripts/gold/ddl_gold.sql
```

### Workflow 2: Daily Data Load

```sql
-- 1. Load raw data
EXEC bronze.load_bronze;

-- 2. Transform to Silver
EXEC silver.load_silver;

-- 3. Validate data quality
EXEC scripts/tests/quality_checks_silver.sql
EXEC scripts/tests/quality_checks_gold.sql

-- 4. Query Gold layer for reporting
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.fact_sales;
```

### Workflow 3: Troubleshooting

```sql
-- Check raw Bronze data
SELECT TOP 100 * FROM bronze.crm_cust_info;

-- Check cleaned Silver data
SELECT TOP 100 * FROM silver.crm_cust_info;

-- Run quality checks to find issues
EXEC scripts/tests/quality_checks_silver.sql

-- Query Gold dimension with joins
SELECT * FROM gold.dim_customers WHERE country = 'United States';
```

## Customization & Extension

### Adding New Source Tables

1. Add table schema to `scripts/bronze/ddl_bronze.sql`
2. Add BULK INSERT step to `scripts/bronze/proc_load_bronze.sql`
3. Add transformation logic to `scripts/silver/proc_load_silver.sql`
4. Create views in `scripts/gold/ddl_gold.sql` if needed
5. Add quality checks to `tests/quality_checks_*.sql`

### Modifying Transformation Logic

Edit `scripts/silver/proc_load_silver.sql` to adjust:
- Data type conversions
- Categorical mappings
- Null handling strategies
- Deduplication logic
- Date calculations

### Adding Aggregate Tables

For performance optimization, you can add aggregate tables in the Gold layer:

```sql
CREATE VIEW gold.sales_by_customer AS
SELECT 
    dc.customer_key,
    dc.customer_number,
    dc.first_name,
    dc.last_name,
    COUNT(*) AS order_count,
    SUM(fs.sales_amount) AS total_sales
FROM gold.fact_sales fs
JOIN gold.dim_customers dc ON fs.customer_key = dc.customer_key
GROUP BY dc.customer_key, dc.customer_number, dc.first_name, dc.last_name;
```

## Contributing

Contributions are welcome! To contribute:

1. **Report Issues**: Open an issue describing bugs or desired features
2. **Submit Enhancements**: 
   - Fork the repository
   - Create a feature branch
   - Make your changes
   - Submit a pull request with clear descriptions

### Contributing Guidelines

- Include descriptive comments in SQL scripts
- Follow existing naming conventions
- Add quality checks for new transformations
- Update documentation for schema changes
- Test thoroughly before submitting

## License

This project is open source and available under the MIT License. See LICENSE file for details.

---

## Additional Resources

### Documentation Files

- `docs/data_architecture.png` - Complete system architecture
- `docs/data_flow.png` - ETL pipeline data flow
- `docs/data_model.png` - Star schema dimensional model
- `docs/data_integration.png` - Multi-source integration pattern

### External References

- [Microsoft SQL Server Documentation](https://learn.microsoft.com/sql/)
- [Medallion Architecture Pattern](https://www.databricks.com/glossary/medallion-architecture)
- [Star Schema Design](https://en.wikipedia.org/wiki/Star_schema)
- [Data Warehouse Concepts](https://learn.microsoft.com/sql/relational-databases/databases/databases)

---

## Troubleshooting

### Issue: "File not found" during BULK INSERT

**Solution**: Update file paths in `scripts/bronze/proc_load_bronze.sql` to match your actual dataset location.

### Issue: "BULK INSERT requires authentication"

**Solution**: Ensure SQL Server has read permissions to the CSV file directories.

### Issue: Data type conversion errors in Silver layer

**Solution**: Check CSV file format matches expected columns. Run quality checks to identify problematic rows.

### Issue: Gold layer views return no data

**Solution**: Ensure Bronze layer is loaded first, then Silver layer is loaded. Verify Silver layer has data before querying Gold.

### Issue: Primary key violations during Silver load

**Solution**: Check for duplicate business keys in Bronze layer. Review deduplication logic if necessary.

---

**Last Updated**: 2026-08-30  
**Repository**: https://github.com/louahabi79/SQL_DWH  
**Author**: Abdenour LOUAHABI
