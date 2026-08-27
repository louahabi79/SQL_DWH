/*

# Create Database and Schemas

Script Purpose:
This script initializes the 'DataWareHouse' environment from scratch.
It safely removes any existing instance of the database and provisions
a new one containing the foundational medallion architecture schemas
(bronze, silver, and gold) for data staging and processing.

# WARNING:
This script contains destructive operations. Dropping the 'DataWareHouse'
database will permanently delete all existing tables, views, data, and
configurations within it. Ensure you have backups before proceeding in
a non-development environment.

*/

-- Drop and recreate the database
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWareHouse')
BEGIN
ALTER DATABASE DataWareHouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE DataWareHouse;
END;
GO

-- Create the database
CREATE DATABASE DataWareHouse;
GO

USE DataWareHouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
