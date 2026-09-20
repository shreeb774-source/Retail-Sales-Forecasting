
/* ============================================================
   PHASE 1 — SNOWFLAKE ENVIRONMENT SETUP
============================================================ */

CREATE DATABASE IF NOT EXISTS RETAIL_FORECASTING;

USE DATABASE RETAIL_FORECASTING;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CLEAN;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

CREATE WAREHOUSE IF NOT EXISTS RETAIL_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE RETAIL_WH;

/* ------------------------------------------------------------
   Check Current Database and Schema
------------------------------------------------------------ */

SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();

USE DATABASE RETAIL_FORECASTING;
USE SCHEMA RAW;

SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();

/* ============================================================
   PHASE 2 — RAW DATA VALIDATION
============================================================ */


/* ------------------------------------------------------------
   Step 2.1 — Check Raw Tables
------------------------------------------------------------ */

SHOW TABLES IN SCHEMA RETAIL_FORECASTING.RAW;

/* ------------------------------------------------------------
   Step 2.2 — Row Count Validation
------------------------------------------------------------ */

SELECT 'CALENDAR' AS TABLE_NAME, COUNT(*) AS ROW_COUNT
FROM RETAIL_FORECASTING.RAW.CALENDAR

UNION ALL

SELECT 'SELL_PRICES', COUNT(*)
FROM RETAIL_FORECASTING.RAW.SELL_PRICES

UNION ALL

SELECT 'SALES_TRAIN_VALIDATION', COUNT(*)
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_VALIDATION

UNION ALL

SELECT 'SALES_TRAIN_EVALUATION', COUNT(*)
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_EVALUATION

UNION ALL

SELECT 'SAMPLE_SUBMISSION', COUNT(*)
FROM RETAIL_FORECASTING.RAW.SAMPLE_SUBMISSION;

/* ------------------------------------------------------------
   Step 2.3 — Inspect Calendar Structure
------------------------------------------------------------ */

DESCRIBE TABLE RETAIL_FORECASTING.RAW.CALENDAR;


/* ============================================================
   PHASE 3 — RAW DATA QUALITY CHECKS
============================================================ */


/* ------------------------------------------------------------
   Step 3.1 — Calendar Data Preview
------------------------------------------------------------ */

SELECT *
FROM RETAIL_FORECASTING.RAW.CALENDAR
LIMIT 10;


/* ------------------------------------------------------------
   Step 3.2 — Calendar Row Count
------------------------------------------------------------ */

SELECT COUNT(*) AS TOTAL_ROWS
FROM RETAIL_FORECASTING.RAW.CALENDAR;


/* ------------------------------------------------------------
   Step 3.3 — Calendar Date Range
------------------------------------------------------------ */

SELECT
    MIN(DATE) AS MIN_DATE,
    MAX(DATE) AS MAX_DATE
FROM RETAIL_FORECASTING.RAW.CALENDAR;

/* ------------------------------------------------------------
   Step 3.4 — Calendar NULL Check
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DATE) AS DATE_NON_NULL,
    COUNT(WM_YR_WK) AS WEEK_NON_NULL,
    COUNT(MONTH) AS MONTH_NON_NULL,
    COUNT(YEAR) AS YEAR_NON_NULL
FROM RETAIL_FORECASTING.RAW.CALENDAR;

/* ------------------------------------------------------------
   Step 3.5 — Calendar Duplicate Check
------------------------------------------------------------ */

SELECT
    DATE,
    COUNT(*) AS RECORD_COUNT
FROM RETAIL_FORECASTING.RAW.CALENDAR
GROUP BY DATE
HAVING COUNT(*) > 1;

/* ============================================================
   PHASE 4 — SELL PRICE DATA QUALITY
============================================================ */


/* ------------------------------------------------------------
   Step 4.1 — Price Table Row Count
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS
FROM RETAIL_FORECASTING.RAW.SELL_PRICES;
/* ------------------------------------------------------------
   Step 4.2 — Price Table NULL Check
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(*) - COUNT(STORE_ID) AS MISSING_STORE_ID,
    COUNT(*) - COUNT(ITEM_ID) AS MISSING_ITEM_ID,
    COUNT(*) - COUNT(WM_YR_WK) AS MISSING_WEEK,
    COUNT(*) - COUNT(SELL_PRICE) AS MISSING_PRICE
FROM RETAIL_FORECASTING.RAW.SELL_PRICES;


/* ------------------------------------------------------------
   Step 4.3 — Price Range Check
------------------------------------------------------------ */

SELECT
    MIN(SELL_PRICE) AS MIN_PRICE,
    MAX(SELL_PRICE) AS MAX_PRICE,
    AVG(SELL_PRICE) AS AVG_PRICE
FROM RETAIL_FORECASTING.RAW.SELL_PRICES;


/* ------------------------------------------------------------
   Step 4.4 — Non-positive Price Check
------------------------------------------------------------ */

SELECT *
FROM RETAIL_FORECASTING.RAW.SELL_PRICES
WHERE SELL_PRICE <= 0
LIMIT 20;


/* ============================================================
   PHASE 5 — SALES VALIDATION DATA QUALITY
============================================================ */


/* ------------------------------------------------------------
   Step 5.1 — Validation Data Preview
------------------------------------------------------------ */

SELECT *
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_VALIDATION
LIMIT 10;
/* ------------------------------------------------------------
   Step 5.2 — Validation Row Count
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_VALIDATION;


/* ------------------------------------------------------------
   Step 5.3 — Validation Identifier NULL Check
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(ID) AS ID_PRESENT,
    COUNT(ITEM_ID) AS ITEM_ID_PRESENT,
    COUNT(DEPT_ID) AS DEPT_ID_PRESENT,
    COUNT(CAT_ID) AS CAT_ID_PRESENT,
    COUNT(STORE_ID) AS STORE_ID_PRESENT,
    COUNT(STATE_ID) AS STATE_ID_PRESENT
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_VALIDATION;


/* ------------------------------------------------------------
   Step 5.4 — Validation Product-Store Duplicate Check
------------------------------------------------------------ */

SELECT
    ITEM_ID,
    STORE_ID,
    COUNT(*) AS RECORD_COUNT
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_VALIDATION
GROUP BY ITEM_ID, STORE_ID
HAVING COUNT(*) > 1;

/* ============================================================
   PHASE 6 — SALES EVALUATION DATA QUALITY
============================================================ */


/* ------------------------------------------------------------
   Step 6.1 — Evaluation Data Preview
------------------------------------------------------------ */

SELECT *
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_EVALUATION
LIMIT 10;


/* ------------------------------------------------------------
   Step 6.2 — Evaluation Row Count
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_EVALUATION;


/* ------------------------------------------------------------
   Step 6.3 — Evaluation Identifier NULL Check
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(ID) AS ID_NON_NULL,
    COUNT(ITEM_ID) AS ITEM_ID_NON_NULL,
    COUNT(DEPT_ID) AS DEPT_ID_NON_NULL,
    COUNT(CAT_ID) AS CAT_ID_NON_NULL,
    COUNT(STORE_ID) AS STORE_ID_NON_NULL,
    COUNT(STATE_ID) AS STATE_ID_NON_NULL
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_EVALUATION;


/* ------------------------------------------------------------
   Step 6.4 — Evaluation Duplicate ID Check
------------------------------------------------------------ */

SELECT
    ID,
    COUNT(*) AS RECORD_COUNT
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_EVALUATION
GROUP BY ID
HAVING COUNT(*) > 1;


/* ------------------------------------------------------------
   Step 6.5 — Evaluation Product-Store Duplicate Check
------------------------------------------------------------ */

SELECT
    ITEM_ID,
    STORE_ID,
    COUNT(*) AS RECORD_COUNT
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_EVALUATION
GROUP BY ITEM_ID, STORE_ID
HAVING COUNT(*) > 1;
/* ------------------------------------------------------------
   Step 6.6 — Evaluation Daily Sales Value Check
------------------------------------------------------------ */

SELECT
    MIN(D_1) AS MIN_D1,
    MAX(D_1) AS MAX_D1,
    AVG(D_1) AS AVG_D1
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_EVALUATION;


/* ------------------------------------------------------------
   Step 6.7 — Evaluation NULL / Negative Sales Check
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(CASE WHEN D_1 IS NULL THEN 1 END) AS NULL_D1,
    COUNT(CASE WHEN D_1 < 0 THEN 1 END) AS NEGATIVE_D1,
    SUM(D_1) AS TOTAL_D1_SALES
FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_EVALUATION;
/* ============================================================
   PHASE 7 — CLEAN DATA LAYER
============================================================ */


/* ------------------------------------------------------------
   Step 7.1 — Clean Calendar Table
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.CLEAN.CALENDAR_CLEAN AS

SELECT
    D AS DAY_ID,
    DATE,
    WM_YR_WK,
    WEEKDAY,
    WDAY,
    MONTH,
    YEAR,
    EVENT_NAME_1,
    EVENT_TYPE_1,
    EVENT_NAME_2,
    EVENT_TYPE_2,
    SNAP_CA,
    SNAP_TX,
    SNAP_WI

FROM RETAIL_FORECASTING.RAW.CALENDAR;


/* Check Clean Calendar */

SELECT *
FROM RETAIL_FORECASTING.CLEAN.CALENDAR_CLEAN
LIMIT 10;

SELECT COUNT(*) AS TOTAL_ROWS
FROM RETAIL_FORECASTING.CLEAN.CALENDAR_CLEAN;


/* ------------------------------------------------------------
   Step 7.2 — Clean Sell Price Table
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.CLEAN.SELL_PRICES_CLEAN AS

SELECT
    STORE_ID,
    ITEM_ID,
    WM_YR_WK,
    SELL_PRICE

FROM RETAIL_FORECASTING.RAW.SELL_PRICES;


/* Check Clean Prices */

SELECT *
FROM RETAIL_FORECASTING.CLEAN.SELL_PRICES_CLEAN
LIMIT 10;

SELECT COUNT(*) AS TOTAL_ROWS
FROM RETAIL_FORECASTING.CLEAN.SELL_PRICES_CLEAN;
/* ============================================================
   PHASE 8 — SALES DATA TRANSFORMATION
============================================================ */


/* ------------------------------------------------------------
   Step 8.1 — Convert Wide Sales Data into Daily Long Format
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.CLEAN.SALES_DAILY AS

SELECT
    S.ID,
    S.ITEM_ID,
    S.DEPT_ID,
    S.CAT_ID,
    S.STORE_ID,
    S.STATE_ID,
    F.KEY::VARCHAR AS DAY_ID,
    F.VALUE::NUMBER AS SALES

FROM
(
    SELECT
        ID,
        ITEM_ID,
        DEPT_ID,
        CAT_ID,
        STORE_ID,
        STATE_ID,

        OBJECT_CONSTRUCT_KEEP_NULL(
            * EXCLUDE (
                ID,
                ITEM_ID,
                DEPT_ID,
                CAT_ID,
                STORE_ID,
                STATE_ID
            )
        ) AS SALES_OBJECT

    FROM RETAIL_FORECASTING.RAW.SALES_TRAIN_VALIDATION

) AS S,

LATERAL FLATTEN(
    INPUT => S.SALES_OBJECT
) AS F

WHERE STARTSWITH(F.KEY::VARCHAR, 'D_');
/* ------------------------------------------------------------
   Step 8.2 — Check Daily Sales Transformation
------------------------------------------------------------ */

SELECT *
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY
LIMIT 20;


/* ------------------------------------------------------------
   Step 8.3 — Daily Sales Row Count
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY;


/* ------------------------------------------------------------
   Step 8.4 — Daily Sales by Day ID
------------------------------------------------------------ */

SELECT
    DAY_ID,
    SUM(SALES) AS TOTAL_SALES
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY
GROUP BY DAY_ID
ORDER BY DAY_ID
LIMIT 20;


/* ------------------------------------------------------------
   Step 8.5 — Sales Range Check
------------------------------------------------------------ */

SELECT
    MIN(SALES) AS MIN_SALES,
    MAX(SALES) AS MAX_SALES,
    AVG(SALES) AS AVG_SALES
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY;


/* ------------------------------------------------------------
   Step 8.6 — Sales Distribution
------------------------------------------------------------ */

SELECT
    SALES,
    COUNT(*) AS NUMBER_OF_RECORDS
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY
GROUP BY SALES
ORDER BY SALES
LIMIT 20;


/* ------------------------------------------------------------
   Step 8.7 — Zero Sales Distribution
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_RECORDS,
    COUNT_IF(SALES = 0) AS ZERO_SALES_RECORDS,

    ROUND(
        COUNT_IF(SALES = 0) * 100.0 / COUNT(*),
        2
    ) AS ZERO_SALES_PERCENTAGE,

    COUNT_IF(SALES > 0) AS NON_ZERO_SALES_RECORDS

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY;

/* ============================================================
   PHASE 9 — CALENDAR ENRICHMENT
============================================================ */


/* ------------------------------------------------------------
   Step 9.1 — Join Daily Sales with Calendar
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.CLEAN.SALES_DAILY_CALENDAR AS

SELECT
    S.ID,
    S.ITEM_ID,
    S.DEPT_ID,
    S.CAT_ID,
    S.STORE_ID,
    S.STATE_ID,
    S.DAY_ID,
    S.SALES,

    C.DATE,
    C.WM_YR_WK,
    C.WEEKDAY,
    C.WDAY,
    C.MONTH,
    C.YEAR,
    C.EVENT_NAME_1,
    C.EVENT_TYPE_1,
    C.EVENT_NAME_2,
    C.EVENT_TYPE_2,
    C.SNAP_CA,
    C.SNAP_TX,
    C.SNAP_WI

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY AS S

LEFT JOIN RETAIL_FORECASTING.CLEAN.CALENDAR_CLEAN AS C

    ON LOWER(S.DAY_ID) = LOWER(C.DAY_ID);
/* ------------------------------------------------------------
   Step 9.2 — Check Calendar Join
------------------------------------------------------------ */

SELECT *
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_CALENDAR
LIMIT 20;


/* ------------------------------------------------------------
   Step 9.3 — Check Unmatched Calendar Records
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DATE) AS MATCHED_DATE_ROWS,
    COUNT(*) - COUNT(DATE) AS UNMATCHED_ROWS
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_CALENDAR;

/* ============================================================
   PHASE 10 — PRICE ENRICHMENT
============================================================ */


/* ------------------------------------------------------------
   Step 10.1 — Add Price Information
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED AS

SELECT
    S.ID,
    S.ITEM_ID,
    S.DEPT_ID,
    S.CAT_ID,
    S.STORE_ID,
    S.STATE_ID,
    S.DAY_ID,
    S.SALES,
    S.DATE,
    S.WM_YR_WK,
    S.WEEKDAY,
    S.WDAY,
    S.MONTH,
    S.YEAR,
    S.EVENT_NAME_1,
    S.EVENT_TYPE_1,
    S.EVENT_NAME_2,
    S.EVENT_TYPE_2,
    S.SNAP_CA,
    S.SNAP_TX,
    S.SNAP_WI,
    P.SELL_PRICE

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_CALENDAR AS S

LEFT JOIN RETAIL_FORECASTING.CLEAN.SELL_PRICES_CLEAN AS P

    ON S.ITEM_ID = P.ITEM_ID
    AND S.STORE_ID = P.STORE_ID
    AND S.WM_YR_WK = P.WM_YR_WK;
/* ------------------------------------------------------------
   Step 10.2 — Check Price Availability
------------------------------------------------------------ */

SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT(SELL_PRICE) AS PRICE_AVAILABLE,
    COUNT(*) - COUNT(SELL_PRICE) AS PRICE_MISSING
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED;


/* ------------------------------------------------------------
   Step 10.3 — Preview Enriched Data
------------------------------------------------------------ */

SELECT
    ITEM_ID,
    STORE_ID,
    DAY_ID,
    DATE,
    SALES,
    SELL_PRICE
FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED
LIMIT 10;

/* ============================================================
   PHASE 11 — DESCRIPTIVE BUSINESS ANALYSIS
============================================================ */


/* ------------------------------------------------------------
   Step 11.1 — Daily Sales Summary
   Business Question:
   How does total retail demand change over time?
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.DAILY_SALES_SUMMARY AS

SELECT
    DATE,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SALES) AS AVERAGE_SALES,
    COUNT(DISTINCT ITEM_ID) AS ACTIVE_PRODUCTS,
    COUNT(DISTINCT STORE_ID) AS ACTIVE_STORES

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

GROUP BY DATE

ORDER BY DATE;


/* Check */

SELECT *
FROM RETAIL_FORECASTING.ANALYTICS.DAILY_SALES_SUMMARY
LIMIT 20;


/* ------------------------------------------------------------
   Step 11.2 — Monthly Sales Performance
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.MONTHLY_SALES AS

SELECT
    YEAR,
    MONTH,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SALES) AS AVERAGE_SALES,
    COUNT(DISTINCT ITEM_ID) AS ACTIVE_PRODUCTS,
    COUNT(DISTINCT STORE_ID) AS ACTIVE_STORES

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

GROUP BY
    YEAR,
    MONTH

ORDER BY
    YEAR,
    MONTH;


/* Check */

SELECT *
FROM RETAIL_FORECASTING.ANALYTICS.MONTHLY_SALES
ORDER BY YEAR, MONTH;


/* ------------------------------------------------------------
   Step 11.3 — Product Performance
   Business Question:
   Which products generate the highest demand?
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.PRODUCT_PERFORMANCE AS

SELECT
    ITEM_ID,
    CAT_ID,
    DEPT_ID,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SALES) AS AVERAGE_DAILY_SALES,
    COUNT(DISTINCT STORE_ID) AS NUMBER_OF_STORES

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

GROUP BY
    ITEM_ID,
    CAT_ID,
    DEPT_ID

ORDER BY TOTAL_SALES DESC;


/* Top 10 Products */

SELECT
    ITEM_ID,
    CAT_ID,
    DEPT_ID,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_STORES
FROM RETAIL_FORECASTING.ANALYTICS.PRODUCT_PERFORMANCE
ORDER BY TOTAL_SALES DESC
LIMIT 10;


/* Bottom 10 Products */

SELECT
    ITEM_ID,
    CAT_ID,
    DEPT_ID,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_STORES
FROM RETAIL_FORECASTING.ANALYTICS.PRODUCT_PERFORMANCE
ORDER BY TOTAL_SALES ASC
LIMIT 10;


/* ------------------------------------------------------------
   Step 11.4 — Category Performance
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.CATEGORY_PERFORMANCE AS

SELECT
    CAT_ID,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SALES) AS AVERAGE_DAILY_SALES,
    COUNT(DISTINCT ITEM_ID) AS NUMBER_OF_PRODUCTS

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

GROUP BY CAT_ID

ORDER BY TOTAL_SALES DESC;


/* All Categories */

SELECT
    CAT_ID,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_PRODUCTS
FROM RETAIL_FORECASTING.ANALYTICS.CATEGORY_PERFORMANCE
ORDER BY TOTAL_SALES DESC;


/* Top Performing Category */

SELECT
    CAT_ID,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_PRODUCTS
FROM RETAIL_FORECASTING.ANALYTICS.CATEGORY_PERFORMANCE
ORDER BY TOTAL_SALES DESC
LIMIT 1;


/* Top 3 Categories */

SELECT
    CAT_ID,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_PRODUCTS
FROM RETAIL_FORECASTING.ANALYTICS.CATEGORY_PERFORMANCE
ORDER BY TOTAL_SALES DESC
LIMIT 3;


/* ------------------------------------------------------------
   Step 11.5 — Department Performance
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.DEPARTMENT_PERFORMANCE AS

SELECT
    DEPT_ID,
    CAT_ID,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SALES) AS AVERAGE_DAILY_SALES,
    COUNT(DISTINCT ITEM_ID) AS NUMBER_OF_PRODUCTS

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

GROUP BY
    DEPT_ID,
    CAT_ID

ORDER BY TOTAL_SALES DESC;


/* Top 10 Departments */

SELECT
    DEPT_ID,
    CAT_ID,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_PRODUCTS
FROM RETAIL_FORECASTING.ANALYTICS.DEPARTMENT_PERFORMANCE
ORDER BY TOTAL_SALES DESC
LIMIT 10;


/* ------------------------------------------------------------
   Step 11.6 — Store Performance
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.STORE_PERFORMANCE AS

SELECT
    STORE_ID,
    STATE_ID,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SALES) AS AVERAGE_DAILY_SALES,
    COUNT(DISTINCT ITEM_ID) AS NUMBER_OF_PRODUCTS

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

GROUP BY
    STORE_ID,
    STATE_ID

ORDER BY TOTAL_SALES DESC;


/* Top 10 Stores */

SELECT
    STORE_ID,
    STATE_ID,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_PRODUCTS
FROM RETAIL_FORECASTING.ANALYTICS.STORE_PERFORMANCE
ORDER BY TOTAL_SALES DESC
LIMIT 10;


/* ------------------------------------------------------------
   Step 11.7 — State Performance
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.STATE_PERFORMANCE AS

SELECT
    STATE_ID,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SALES) AS AVERAGE_DAILY_SALES,
    COUNT(DISTINCT STORE_ID) AS NUMBER_OF_STORES

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

GROUP BY STATE_ID

ORDER BY TOTAL_SALES DESC;


/* Top Performing State */

SELECT
    STATE_ID,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_STORES
FROM RETAIL_FORECASTING.ANALYTICS.STATE_PERFORMANCE
ORDER BY TOTAL_SALES DESC
LIMIT 1;


/* ============================================================
   PHASE 12 — DIAGNOSTIC ANALYSIS
============================================================ */


/* ------------------------------------------------------------
   Step 12.1 — Event vs Normal Day Analysis

   Purpose:
   Compare average total daily sales on event days
   versus normal days.
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.EVENT_PERFORMANCE AS

SELECT
    DAY_TYPE,
    COUNT(*) AS NUMBER_OF_DAYS,
    SUM(DAILY_TOTAL_SALES) AS TOTAL_SALES,
    ROUND(AVG(DAILY_TOTAL_SALES), 2) AS AVERAGE_TOTAL_SALES_PER_DAY

FROM
(
    SELECT
        DATE,

        CASE
            WHEN EVENT_NAME_1 IS NOT NULL
              OR EVENT_NAME_2 IS NOT NULL
            THEN 'EVENT_DAY'
            ELSE 'NORMAL_DAY'
        END AS DAY_TYPE,

        SUM(SALES) AS DAILY_TOTAL_SALES

    FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

    GROUP BY
        DATE,
        CASE
            WHEN EVENT_NAME_1 IS NOT NULL
              OR EVENT_NAME_2 IS NOT NULL
            THEN 'EVENT_DAY'
            ELSE 'NORMAL_DAY'
        END
)

GROUP BY DAY_TYPE;


/* Check Event Performance */

SELECT *
FROM RETAIL_FORECASTING.ANALYTICS.EVENT_PERFORMANCE
ORDER BY DAY_TYPE;


/* ------------------------------------------------------------
   Step 12.2 — Price vs Sales Analysis
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.PRICE_SALES_ANALYSIS AS

SELECT
    ITEM_ID,
    STORE_ID,
    SELL_PRICE,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SALES) AS AVERAGE_DAILY_SALES,
    COUNT(*) AS NUMBER_OF_DAYS

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

WHERE SELL_PRICE IS NOT NULL

GROUP BY
    ITEM_ID,
    STORE_ID,
    SELL_PRICE;


/* Price Band vs Sales */

SELECT
    CASE
        WHEN SELL_PRICE < 2 THEN '< $2'
        WHEN SELL_PRICE >= 2 AND SELL_PRICE < 5 THEN '$2 - $5'
        WHEN SELL_PRICE >= 5 AND SELL_PRICE < 10 THEN '$5 - $10'
        WHEN SELL_PRICE >= 10 AND SELL_PRICE < 20 THEN '$10 - $20'
        ELSE '$20+'
    END AS PRICE_BAND,

    COUNT(*) AS NUMBER_OF_RECORDS,
    SUM(TOTAL_SALES) AS TOTAL_SALES,
    ROUND(AVG(AVERAGE_DAILY_SALES), 2) AS AVERAGE_DAILY_SALES

FROM RETAIL_FORECASTING.ANALYTICS.PRICE_SALES_ANALYSIS

GROUP BY
    CASE
        WHEN SELL_PRICE < 2 THEN '< $2'
        WHEN SELL_PRICE >= 2 AND SELL_PRICE < 5 THEN '$2 - $5'
        WHEN SELL_PRICE >= 5 AND SELL_PRICE < 10 THEN '$5 - $10'
        WHEN SELL_PRICE >= 10 AND SELL_PRICE < 20 THEN '$10 - $20'
        ELSE '$20+'
    END

ORDER BY MIN(SELL_PRICE);


/* Top Product-Store Combinations */

SELECT
    ITEM_ID,
    STORE_ID,
    SELL_PRICE,
    TOTAL_SALES,
    AVERAGE_DAILY_SALES,
    NUMBER_OF_DAYS
FROM RETAIL_FORECASTING.ANALYTICS.PRICE_SALES_ANALYSIS
ORDER BY TOTAL_SALES DESC
LIMIT 20;


/* Price vs Average Demand */

SELECT
    SELL_PRICE,
    COUNT(*) AS PRODUCT_STORE_RECORDS,
    ROUND(AVG(AVERAGE_DAILY_SALES), 2) AS AVG_DEMAND,
    SUM(TOTAL_SALES) AS TOTAL_SALES
FROM RETAIL_FORECASTING.ANALYTICS.PRICE_SALES_ANALYSIS
GROUP BY SELL_PRICE
ORDER BY SELL_PRICE;


/* ============================================================
   PHASE 13 — PRODUCT TREND ANALYSIS
============================================================ */


/* ------------------------------------------------------------
   Step 13.1 — Product Growth / Decline Analysis

   Note:
   Compare equal-length early and later periods.
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.PRODUCT_TREND AS

WITH DATE_RANGE AS
(
    SELECT
        MIN(DATE) AS MIN_DATE,
        MAX(DATE) AS MAX_DATE
    FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED
),

PERIODS AS
(
    SELECT
        MIN_DATE,
        MAX_DATE,
        DATEADD(DAY, 365, MIN_DATE) AS EARLY_END_DATE,
        DATEADD(DAY, -365, MAX_DATE) AS LATER_START_DATE
    FROM DATE_RANGE
)

SELECT
    S.ITEM_ID,

    SUM(
        CASE
            WHEN S.DATE >= P.MIN_DATE
             AND S.DATE < P.EARLY_END_DATE
            THEN S.SALES
            ELSE 0
        END
    ) AS EARLY_PERIOD_SALES,

    SUM(
        CASE
            WHEN S.DATE > P.LATER_START_DATE
             AND S.DATE <= P.MAX_DATE
            THEN S.SALES
            ELSE 0
        END
    ) AS LATER_PERIOD_SALES

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED AS S

CROSS JOIN PERIODS AS P

GROUP BY S.ITEM_ID;


/* ------------------------------------------------------------
   Step 13.2 — Top Growing Products
------------------------------------------------------------ */

SELECT
    ITEM_ID,
    EARLY_PERIOD_SALES,
    LATER_PERIOD_SALES,
    LATER_PERIOD_SALES - EARLY_PERIOD_SALES AS SALES_CHANGE
FROM RETAIL_FORECASTING.ANALYTICS.PRODUCT_TREND
ORDER BY SALES_CHANGE DESC
LIMIT 20;


/* ------------------------------------------------------------
   Step 13.3 — Declining Products
------------------------------------------------------------ */

SELECT
    ITEM_ID,
    EARLY_PERIOD_SALES,
    LATER_PERIOD_SALES,
    LATER_PERIOD_SALES - EARLY_PERIOD_SALES AS SALES_CHANGE
FROM RETAIL_FORECASTING.ANALYTICS.PRODUCT_TREND
ORDER BY SALES_CHANGE ASC
LIMIT 20;


/* ============================================================
   PHASE 14 — FORECAST INPUT PREPARATION
============================================================ */


/* ------------------------------------------------------------
   Step 14.1 — Create Forecast Input Table
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.FORECAST_INPUT AS

SELECT
    ITEM_ID,
    DEPT_ID,
    CAT_ID,
    STORE_ID,
    STATE_ID,
    DATE,
    SALES,
    SELL_PRICE,
    WM_YR_WK,
    WEEKDAY,
    MONTH,
    YEAR,
    EVENT_NAME_1,
    EVENT_TYPE_1,
    EVENT_NAME_2,
    EVENT_TYPE_2,
    SNAP_CA,
    SNAP_TX,
    SNAP_WI

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED;


/* Check Forecast Input */

SELECT *
FROM RETAIL_FORECASTING.ANALYTICS.FORECAST_INPUT
LIMIT 20;


/* ============================================================
   PHASE 15 — SMALLER FORECAST DATASET
============================================================ */


/* ------------------------------------------------------------
   Step 15.1 — Store-Category Daily Demand
------------------------------------------------------------ */

CREATE OR REPLACE TABLE RETAIL_FORECASTING.ANALYTICS.DAILY_STORE_CATEGORY_DEMAND AS

SELECT
    DATE,
    STORE_ID,
    STATE_ID,
    CAT_ID,
    SUM(SALES) AS TOTAL_SALES,
    AVG(SELL_PRICE) AS AVERAGE_PRICE

FROM RETAIL_FORECASTING.CLEAN.SALES_DAILY_ENRICHED

GROUP BY
    DATE,
    STORE_ID,
    STATE_ID,
    CAT_ID

ORDER BY DATE;


/* Check */

SELECT *
FROM RETAIL_FORECASTING.ANALYTICS.DAILY_STORE_CATEGORY_DEMAND
LIMIT 20;


/* ------------------------------------------------------------
   Step 15.2 — Category-wise Demand Performance
------------------------------------------------------------ */

SELECT
    CAT_ID,
    SUM(DAILY_DEMAND) AS TOTAL_DEMAND,
    ROUND(AVG(DAILY_DEMAND), 2) AS AVERAGE_DAILY_DEMAND,
    COUNT(*) AS NUMBER_OF_DAYS

FROM
(
    SELECT
        CAT_ID,
        DATE,
        SUM(TOTAL_SALES) AS DAILY_DEMAND

    FROM RETAIL_FORECASTING.ANALYTICS.DAILY_STORE_CATEGORY_DEMAND

    GROUP BY
        CAT_ID,
        DATE
)

GROUP BY CAT_ID

ORDER BY TOTAL_DEMAND DESC;


/* ------------------------------------------------------------
   Step 15.3 — Top 3 Categories by Demand
------------------------------------------------------------ */

SELECT
    CAT_ID,
    SUM(DAILY_DEMAND) AS TOTAL_DEMAND,
    ROUND(AVG(DAILY_DEMAND), 2) AS AVERAGE_DAILY_DEMAND

FROM
(
    SELECT
        CAT_ID,
        DATE,
        SUM(TOTAL_SALES) AS DAILY_DEMAND

    FROM RETAIL_FORECASTING.ANALYTICS.DAILY_STORE_CATEGORY_DEMAND

    GROUP BY
        CAT_ID,
        DATE
)

GROUP BY CAT_ID

ORDER BY TOTAL_DEMAND DESC

LIMIT 3;


/* ------------------------------------------------------------
   Step 15.4 — Store-wise Demand Performance
------------------------------------------------------------ */

SELECT
    STORE_ID,
    STATE_ID,
    SUM(TOTAL_SALES) AS TOTAL_DEMAND,
    ROUND(AVG(TOTAL_SALES), 2) AS AVERAGE_DAILY_DEMAND,
    COUNT(DISTINCT DATE) AS NUMBER_OF_DAYS

FROM RETAIL_FORECASTING.ANALYTICS.DAILY_STORE_CATEGORY_DEMAND

GROUP BY
    STORE_ID,
    STATE_ID

ORDER BY TOTAL_DEMAND DESC;


/* ------------------------------------------------------------
   Step 15.5 — Top 10 Stores by Demand
------------------------------------------------------------ */

SELECT
    STORE_ID,
    STATE_ID,
    SUM(TOTAL_SALES) AS TOTAL_DEMAND,
    ROUND(AVG(TOTAL_SALES), 2) AS AVERAGE_DAILY_DEMAND

FROM RETAIL_FORECASTING.ANALYTICS.DAILY_STORE_CATEGORY_DEMAND

GROUP BY
    STORE_ID,
    STATE_ID

ORDER BY TOTAL_DEMAND DESC

LIMIT 10;


/* ============================================================
   PHASE 16 — FINAL SNOWFLAKE VALIDATION
============================================================ */


/* ------------------------------------------------------------
   Step 16.1 — Check Clean Layer Tables
------------------------------------------------------------ */

SHOW TABLES IN SCHEMA RETAIL_FORECASTING.CLEAN;


/* ------------------------------------------------------------
   Step 16.2 — Check Analytics Layer Tables
------------------------------------------------------------ */

SHOW TABLES IN SCHEMA RETAIL_FORECASTING.ANALYTICS;


/* ============================================================
   END OF SNOWFLAKE IMPLEMENTATION
============================================================ */
