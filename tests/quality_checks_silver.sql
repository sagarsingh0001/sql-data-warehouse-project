/*
====================================================================================
Quality Checks
====================================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy,
  and standardization across the 'silver' schemas. It includes checks for:
  - Null or duplicate primary keys.
  - Unwanted spaces in string fields.
  - Data Standardization and consistency.
  - Invalid date ranges and orders.
  - Data consistency between related fields.

Usage Notes:
  - Run these checks after data loading Silver Layer.
  - Investigate and resolve any discrepancies found during the checks.
====================================================================================
*/

-- ======================================================================
-- Checking 'silver.crm_cust_info'
-- ======================================================================

-- Check for NULLS or Duplicates in Primary Key.
-- Expectation: No Result.
SELECT 
  cst_id,
  count(*) 
from silver.crm_cust_info 
group by cst_id 
HAVING 
  count(*)>1 OR cst_id is null;

-- Check for Unwanted Spaces.
-- Expectation: No Result.
SELECT cst_firstname
FROM silver.crm_cust_info 
WHERE cst_firstname != TRIM(cst_firstname);

-- Data Standardization & Consistency
SELECT DISTINCT cst_gender FROM silver.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;

-- ======================================================================
-- Checking 'silver.crm_prd_info'
-- ======================================================================

-- Check for Nulls or Duplicates in Primary Key.
-- Expectation: No Result
SELECT prd_id,
COUNT(*) FROM silver.crm_prd_info 
GROUP BY prd_id 
HAVING COUNT(*) > 1 or prd_id IS NULL;


-- Data Enrichment (creating cat_id)
SELECT 
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM silver.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN
(SELECT DISTINCT id FROM silver.erp_px_cat_g1v2)

-- Check for Unwanted Spaces.
-- Expectation: No Result.
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or Negative Numbers
-- Expectation: No Results
SELECT prd_cost 
FROM silver.crm_prd_info 
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders
SELECT * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

-- ======================================================================
-- Checking 'silver.crm_sales_details'
-- ======================================================================

-- Check for Invalid Dates
-- Expectation: No Invalid Dates
SELECT
  NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101

-- Check for Invalid Date Orders (Order Date > Shipping/Due Dates)
-- Expectation: No Results
SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT DISTINCT
  sls_sales,
  sls_quantity,
  sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
  OR sls_sales IS NULL
  OR sls_quantity IS NULL
  OR sls_price IS NULL
  OR sls_sales <= 0
  OR sls_quantity <= 0
  OR price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ======================================================================
-- Checking 'silver.erp_cust_az12'
-- ======================================================================

-- Identify Out-of-Range Dates (checking for bdates greater than 100 and checking for Birthdays in the future.)
SELECT DISTINCT
  bdate 
FROM silver.erp_cust_az12
WHERE bdate < '1926-01-01' 
  OR bdate > GETDATE()

-- Data Standardization and Consistency
SELECT DISTINCT 
  gen
FROM silver.erp_cust_az12

-- ======================================================================
-- Checking 'silver.erp_loc_a101'
-- ======================================================================

-- Checking for Unwanted spaces
SELECT cid FROM silver.erp_loc_a101 where cid != TRIM(cid)
SELECT cntry FROM silver.erp_loc_a101 where cid != TRIM(cid)

-- Data Standardization & Consistency
SELECT DISTINCT 
  cntry
FROM
silver.erp_loc_a101

-- ======================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ======================================================================

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT
  *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
  OR subcat != TRIM(subcat)
  OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT
  maintenance
FROM silver.erp_px_cat_g1v2;


