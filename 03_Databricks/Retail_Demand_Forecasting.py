# Databricks notebook source
print("M5 Retail Sales Forecasting & Demand Prediction")
print("Databricks notebook is working successfully.")

# COMMAND ----------

# 1. LOAD AND CHECK CALENDAR DATA

calendar_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/calendar.csv")
)

print("First 10 Records:")
calendar_df.show(10)

print("Dataset Schema:")
calendar_df.printSchema()

print("Rows:", calendar_df.count())
print("Columns:", len(calendar_df.columns))

# COMMAND ----------

# 2. LOAD AND CHECK SELL PRICES DATA

prices_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sell_prices.csv")
)

print("First 10 Records:")
prices_df.show(10)

print("Dataset Schema:")
prices_df.printSchema()

print("Rows:", prices_df.count())
print("Columns:", len(prices_df.columns))

# COMMAND ----------

# 2. LOAD AND CHECK SELL PRICES DATA

prices_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sell_prices.csv")
)

print("First 10 Records:")
prices_df.show(10)

print("Dataset Schema:")
prices_df.printSchema()

print("Rows:", prices_df.count())
print("Columns:", len(prices_df.columns))

# COMMAND ----------

# 3. LOAD AND CHECK SALES VALIDATION DATA

sales_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sales_train_validation.csv")
)

print("First 5 Records:")
sales_df.show(5)

print("Dataset Schema:")
sales_df.printSchema()

print("Rows:", sales_df.count())
print("Columns:", len(sales_df.columns))

# COMMAND ----------

# 4. IDENTIFY DAILY SALES COLUMNS

id_columns = [
    "id",
    "item_id",
    "dept_id",
    "cat_id",
    "store_id",
    "state_id"
]

day_columns = [
    c for c in sales_df.columns
    if c.startswith("d_")
]

print("Identifier Columns:", id_columns)
print("Number of Daily Sales Columns:", len(day_columns))
print("First 10 Day Columns:", day_columns[:10])
print("Last 10 Day Columns:", day_columns[-10:])

# COMMAND ----------

# 5. CONVERT SALES DATA FROM WIDE TO LONG FORMAT

stack_expr = ", ".join(
    [f"'{c}', `{c}`" for c in day_columns]
)

sales_long_df = sales_df.selectExpr(
    *id_columns,
    f"stack({len(day_columns)}, {stack_expr}) as (day_id, sales)"
)

print("Long-format columns:")
print(sales_long_df.columns)

sales_long_df.show(10)

# COMMAND ----------

# 6. VALIDATE LONG SALES DATA

print("Rows after Wide-to-Long Transformation:", sales_long_df.count())
print("Columns:", len(sales_long_df.columns))

print("Sales Summary:")
sales_long_df.select("sales").summary().show()

# COMMAND ----------

# 7. PREPARE CALENDAR DATA

calendar_clean_df = calendar_df.select(
    "d",
    "date",
    "wm_yr_wk",
    "weekday",
    "wday",
    "month",
    "year",
    "event_name_1",
    "event_type_1",
    "event_name_2",
    "event_type_2",
    "snap_CA",
    "snap_TX",
    "snap_WI"
)

calendar_clean_df.show(10)

# COMMAND ----------

# 8. JOIN SALES WITH CALENDAR

sales_calendar_df = (
    sales_long_df
    .join(
        calendar_clean_df,
        sales_long_df.day_id == calendar_clean_df.d,
        "left"
    )
    .drop("d")
)

print("Sales + Calendar Data:")
sales_calendar_df.show(10)

print("Rows:", sales_calendar_df.count())

# COMMAND ----------

# 9. CHECK CALENDAR JOIN

total_rows = sales_calendar_df.count()

matched_dates = (
    sales_calendar_df
    .filter("date IS NOT NULL")
    .count()
)

print("Total Rows:", total_rows)
print("Rows with Matching Date:", matched_dates)
print("Unmatched Rows:", total_rows - matched_dates)

# COMMAND ----------

# 10. PREPARE SELL PRICE DATA

prices_clean_df = (
    prices_df
    .select(
        "store_id",
        "item_id",
        "wm_yr_wk",
        "sell_price"
    )
    .dropDuplicates([
        "store_id",
        "item_id",
        "wm_yr_wk"
    ])
)

prices_clean_df.show(10)

print("Price Rows:", prices_clean_df.count())

# COMMAND ----------

# 11. JOIN SALES WITH PRICE DATA

sales_enriched_df = (
    sales_calendar_df
    .join(
        prices_clean_df,
        ["store_id", "item_id", "wm_yr_wk"],
        "left"
    )
)

print("Sales + Calendar + Price:")
sales_enriched_df.show(10)

print("Total Rows:", sales_enriched_df.count())

# COMMAND ----------

# 12. CHECK PRICE AVAILABILITY

total_records = sales_enriched_df.count()

price_available = (
    sales_enriched_df
    .filter("sell_price IS NOT NULL")
    .count()
)

price_missing = total_records - price_available

print("Total Records:", total_records)
print("Price Available:", price_available)
print("Price Missing:", price_missing)

# COMMAND ----------

# 13. CREATE DAILY STORE-CATEGORY DEMAND DATASET

daily_demand_df = (
    sales_enriched_df
    .groupBy(
        "date",
        "store_id",
        "state_id",
        "cat_id"
    )
    .agg(
        {"sales": "sum"}
    )
    .withColumnRenamed("sum(sales)", "total_sales")
)

print("Daily Store-Category Demand:")
daily_demand_df.show(10)

print("Rows:", daily_demand_df.count())

# COMMAND ----------

# 14. ADD TIME AND EVENT FEATURES

demand_df = (
    daily_demand_df
    .join(
        calendar_clean_df.select(
            "date",
            "weekday",
            "month",
            "year",
            "event_name_1",
            "event_type_1",
            "event_name_2",
            "event_type_2"
        ),
        "date",
        "left"
    )
)

demand_df.show(10)

print("Rows:", demand_df.count())

# COMMAND ----------

# 15. CHECK DEMAND DATASET

print("Dataset Columns:")
print(demand_df.columns)

print("\nDataset Summary:")
demand_df.describe(
    "total_sales"
).show()

# COMMAND ----------

# 16. CATEGORY-WISE SALES ANALYSIS

category_sales = (
    demand_df
    .groupBy("cat_id")
    .agg(
        {"total_sales": "sum"}
    )
    .withColumnRenamed("sum(total_sales)", "total_sales")
    .orderBy("total_sales", ascending=False)
)

category_sales.show()

# COMMAND ----------

# 17. STORE-WISE SALES ANALYSIS

store_sales = (
    demand_df
    .groupBy("store_id", "state_id")
    .agg(
        {"total_sales": "sum"}
    )
    .withColumnRenamed("sum(total_sales)", "total_sales")
    .orderBy("total_sales", ascending=False)
)

store_sales.show(20)

# COMMAND ----------

# 18. MONTHLY SALES TREND

monthly_sales = (
    demand_df
    .groupBy("year", "month")
    .agg(
        {"total_sales": "sum"}
    )
    .withColumnRenamed("sum(total_sales)", "total_sales")
    .orderBy("year", "month")
)

monthly_sales.show(50)

# COMMAND ----------

# 19. EVENT VS NORMAL DAY ANALYSIS

from pyspark.sql.functions import when, col, sum

event_analysis = (
    demand_df
    .withColumn(
        "day_type",
        when(
            col("event_name_1").isNotNull() |
            col("event_name_2").isNotNull(),
            "EVENT_DAY"
        ).otherwise("NORMAL_DAY")
    )
    .groupBy("day_type")
    .agg(
        sum("total_sales").alias("total_sales")
    )
)

event_analysis.show()

# COMMAND ----------

# 20. PREPARE DATA FOR MACHINE LEARNING

forecast_spark_df = (
    demand_df
    .select(
        "date",
        "store_id",
        "state_id",
        "cat_id",
        "weekday",
        "month",
        "year",
        "event_name_1",
        "event_type_1",
        "total_sales"
    )
    .orderBy("date")
)

print("Forecast Dataset Rows:", forecast_spark_df.count())

forecast_spark_df.show(10)

# COMMAND ----------

# 21. CONVERT SMALL AGGREGATED DATASET TO PANDAS

forecast_pd = forecast_spark_df.toPandas()

print("Rows:", len(forecast_pd))
print("Columns:", len(forecast_pd.columns))

forecast_pd.head()

# COMMAND ----------

# 22. CHECK MISSING VALUES

print("Missing Values:")
print(forecast_pd.isnull().sum())

# COMMAND ----------

# 23. PREPARE DATE COLUMN

import pandas as pd

forecast_pd["date"] = pd.to_datetime(forecast_pd["date"])

forecast_pd = forecast_pd.sort_values(
    ["store_id", "cat_id", "date"]
).reset_index(drop=True)

print("Minimum Date:", forecast_pd["date"].min())
print("Maximum Date:", forecast_pd["date"].max())

forecast_pd.head()

# COMMAND ----------

# 24. CREATE TIME-SERIES FEATURES

forecast_pd["day_of_week"] = forecast_pd["date"].dt.dayofweek
forecast_pd["day_of_month"] = forecast_pd["date"].dt.day
forecast_pd["week_of_year"] = forecast_pd["date"].dt.isocalendar().week.astype(int)
forecast_pd["month_num"] = forecast_pd["date"].dt.month

print("Time-series features created.")

forecast_pd[
    [
        "date",
        "store_id",
        "cat_id",
        "total_sales",
        "day_of_week",
        "day_of_month",
        "week_of_year",
        "month_num"
    ]
].head(10)

# COMMAND ----------

# 25. CREATE LAG FEATURES

group_cols = ["store_id", "cat_id"]

forecast_pd["lag_1"] = (
    forecast_pd
    .groupby(group_cols)["total_sales"]
    .shift(1)
)

forecast_pd["lag_7"] = (
    forecast_pd
    .groupby(group_cols)["total_sales"]
    .shift(7)
)

forecast_pd["lag_28"] = (
    forecast_pd
    .groupby(group_cols)["total_sales"]
    .shift(28)
)

print("Lag features created.")

forecast_pd[
    ["date", "store_id", "cat_id", "total_sales", "lag_1", "lag_7", "lag_28"]
].head(40)

# COMMAND ----------

# 26. CREATE ROLLING AVERAGE FEATURES

forecast_pd["rolling_mean_7"] = (
    forecast_pd
    .groupby(group_cols)["total_sales"]
    .transform(
        lambda x: x.shift(1).rolling(7).mean()
    )
)

forecast_pd["rolling_mean_28"] = (
    forecast_pd
    .groupby(group_cols)["total_sales"]
    .transform(
        lambda x: x.shift(1).rolling(28).mean()
    )
)

print("Rolling features created.")

forecast_pd[
    [
        "date",
        "total_sales",
        "lag_7",
        "lag_28",
        "rolling_mean_7",
        "rolling_mean_28"
    ]
].head(40)

# COMMAND ----------

# 27. REMOVE ROWS WITH MISSING LAG VALUES

model_df = forecast_pd.dropna(
    subset=[
        "lag_1",
        "lag_7",
        "lag_28",
        "rolling_mean_7",
        "rolling_mean_28"
    ]
).copy()

print("Original Rows:", len(forecast_pd))
print("Model Rows:", len(model_df))

# COMMAND ----------

# 28. PREPARE FEATURES AND TARGET

feature_columns = [
    "day_of_week",
    "day_of_month",
    "week_of_year",
    "month_num",
    "lag_1",
    "lag_7",
    "lag_28",
    "rolling_mean_7",
    "rolling_mean_28"
]

X = model_df[feature_columns]
y = model_df["total_sales"]

print("Features:")
print(feature_columns)

print("\nFeature Shape:", X.shape)
print("Target Shape:", y.shape)

# COMMAND ----------

# 29. TIME-BASED TRAIN TEST SPLIT

max_date = model_df["date"].max()
test_start_date = max_date - pd.Timedelta(days=27)

train_df = model_df[
    model_df["date"] < test_start_date
].copy()

test_df = model_df[
    model_df["date"] >= test_start_date
].copy()

X_train = train_df[feature_columns]
y_train = train_df["total_sales"]

X_test = test_df[feature_columns]
y_test = test_df["total_sales"]

print("Training Rows:", len(train_df))
print("Testing Rows:", len(test_df))
print("Test Start Date:", test_df["date"].min())
print("Test End Date:", test_df["date"].max())

# COMMAND ----------

# 30. TRAIN RANDOM FOREST FORECASTING MODEL

from sklearn.ensemble import RandomForestRegressor

model = RandomForestRegressor(
    n_estimators=100,
    max_depth=15,
    random_state=42,
    n_jobs=-1
)

model.fit(X_train, y_train)

print("Random Forest model training completed.")

# COMMAND ----------

# 30. TRAIN RANDOM FOREST FORECASTING MODEL

from sklearn.ensemble import RandomForestRegressor

model = RandomForestRegressor(
    n_estimators=100,
    max_depth=15,
    random_state=42,
    n_jobs=-1
)

model.fit(X_train, y_train)

print("Random Forest model training completed.")

# COMMAND ----------

# 31. GENERATE TEST PREDICTIONS

test_predictions = model.predict(X_test)

test_predictions = test_predictions.clip(min=0)

print("Predictions generated.")

print("First 10 Predictions:")
print(test_predictions[:10])

# COMMAND ----------

# 32. MODEL EVALUATION

from sklearn.metrics import mean_absolute_error, mean_squared_error
import numpy as np

mae = mean_absolute_error(y_test, test_predictions)

rmse = np.sqrt(
    mean_squared_error(y_test, test_predictions)
)

print("Mean Absolute Error (MAE):", round(mae, 2))
print("Root Mean Squared Error (RMSE):", round(rmse, 2))

# COMMAND ----------

# 33. ACTUAL VS PREDICTED SALES

results_df = test_df[
    [
        "date",
        "store_id",
        "cat_id",
        "total_sales"
    ]
].copy()

results_df["predicted_sales"] = test_predictions

results_df["error"] = (
    results_df["total_sales"]
    - results_df["predicted_sales"]
)

results_df.head(20)

# COMMAND ----------

# 34. FEATURE IMPORTANCE

feature_importance = pd.DataFrame({
    "feature": feature_columns,
    "importance": model.feature_importances_
}).sort_values(
    "importance",
    ascending=False
)

print(feature_importance)

# COMMAND ----------

# 35. ACTUAL VS PREDICTED SUMMARY

actual_total = results_df["total_sales"].sum()
predicted_total = results_df["predicted_sales"].sum()

print("Actual Sales:", round(actual_total, 2))
print("Predicted Sales:", round(predicted_total, 2))
print(
    "Difference:",
    round(actual_total - predicted_total, 2)
)

# COMMAND ----------

# 36. TRAIN FINAL MODEL ON FULL HISTORICAL DATA

final_model = RandomForestRegressor(
    n_estimators=100,
    max_depth=15,
    random_state=42,
    n_jobs=-1
)

X_full = model_df[feature_columns]
y_full = model_df["total_sales"]

final_model.fit(X_full, y_full)

print("Final model trained on full historical dataset.")

# COMMAND ----------

# 37. IDENTIFY FUTURE FORECAST DATES

historical_max_date = forecast_pd["date"].max()

future_calendar = (
    calendar_clean_df
    .filter(col("date") > str(historical_max_date))
    .orderBy("date")
)

future_calendar.show(35)

print(
    "Future Calendar Rows:",
    future_calendar.count()
)

# COMMAND ----------

# 38. LOAD SALES EVALUATION DATA

evaluation_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sales_train_evaluation.csv")
)

print("Rows:", evaluation_df.count())
print("Columns:", len(evaluation_df.columns))

# COMMAND ----------

# 39. IDENTIFY FUTURE SALES COLUMNS

evaluation_day_columns = [
    c for c in evaluation_df.columns
    if c.startswith("d_")
]

validation_day_columns = [
    c for c in sales_df.columns
    if c.startswith("d_")
]

future_day_columns = [
    c for c in evaluation_day_columns
    if c not in validation_day_columns
]

print("Validation Daily Columns:", len(validation_day_columns))
print("Evaluation Daily Columns:", len(evaluation_day_columns))
print("Future Daily Columns:", len(future_day_columns))

print("Future Days:", future_day_columns)

# COMMAND ----------

# 40. CREATE FUTURE ACTUAL SALES DATA

future_stack_expr = ", ".join(
    [f"'{c}', `{c}`" for c in future_day_columns]
)

future_actual_df = evaluation_df.selectExpr(
    *id_columns,
    f"stack({len(future_day_columns)}, {future_stack_expr}) as (day_id, actual_sales)"
)

future_actual_df.show(10)

print("Future Actual Rows:", future_actual_df.count())

# COMMAND ----------

# 41. AGGREGATE FUTURE ACTUAL SALES

future_actual_agg = (
    future_actual_df
    .join(
        calendar_clean_df.select("d", "date"),
        future_actual_df.day_id == calendar_clean_df.d,
        "left"
    )
    .groupBy(
        "date",
        "store_id",
        "state_id",
        "cat_id"
    )
    .agg(
        {"actual_sales": "sum"}
    )
    .withColumnRenamed(
        "sum(actual_sales)",
        "actual_sales"
    )
)

future_actual_agg.show(10)

# COMMAND ----------

# 42. FINAL FORECAST OUTPUT

final_forecast = results_df[
    [
        "date",
        "store_id",
        "cat_id",
        "total_sales",
        "predicted_sales"
    ]
].copy()

final_forecast = final_forecast.rename(
    columns={
        "total_sales": "actual_sales"
    }
)

final_forecast.head(20)

# COMMAND ----------

# 43. SAVE FORECAST OUTPUT

final_forecast.to_csv(
    "/Volumes/workspace/default/raw/m5_forecast_results.csv",
    index=False
)

print("Forecast results saved successfully.")

# COMMAND ----------

# 44. SAVE MODEL EVALUATION RESULTS

evaluation_results = pd.DataFrame({
    "metric": [
        "MAE",
        "RMSE"
    ],
    "value": [
        mae,
        rmse
    ]
})

evaluation_results.to_csv(
    "/Volumes/workspace/default/raw/m5_model_evaluation.csv",
    index=False
)

print("Model evaluation results saved.")

# COMMAND ----------

# 46. RECREATE DAILY SALES DATA FOR POWER BI

from pyspark.sql.functions import col

# Load sales validation data
sales_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sales_train_validation.csv")
)

# Load calendar data
calendar_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/calendar.csv")
)

# Identify columns
id_columns = [
    "id",
    "item_id",
    "dept_id",
    "cat_id",
    "store_id",
    "state_id"
]

day_columns = [
    c for c in sales_df.columns
    if c.startswith("d_")
]

# Convert sales from wide to long format
stack_expr = ", ".join(
    [f"'{c}', `{c}`" for c in day_columns]
)

sales_long_df = sales_df.selectExpr(
    *id_columns,
    f"stack({len(day_columns)}, {stack_expr}) as (day_id, sales)"
)

# Prepare calendar
calendar_clean_df = calendar_df.select(
    "d",
    "date",
    "weekday",
    "month",
    "year",
    "event_name_1",
    "event_type_1",
    "event_name_2",
    "event_type_2"
)

# Join sales with calendar
sales_calendar_df = (
    sales_long_df
    .join(
        calendar_clean_df,
        sales_long_df.day_id == calendar_clean_df.d,
        "left"
    )
    .drop("d")
)

# Create daily store-category demand
daily_demand_df = (
    sales_calendar_df
    .groupBy(
        "date",
        "store_id",
        "state_id",
        "cat_id"
    )
    .agg(
        {"sales": "sum"}
    )
    .withColumnRenamed(
        "sum(sales)",
        "total_sales"
    )
)

# Add calendar and event information
demand_df = (
    daily_demand_df
    .join(
        calendar_clean_df.select(
            "date",
            "weekday",
            "month",
            "year",
            "event_name_1",
            "event_type_1",
            "event_name_2",
            "event_type_2"
        ),
        "date",
        "left"
    )
)

print("Daily Sales Dataset Created")
print("Rows:", demand_df.count())
print("Columns:", len(demand_df.columns))

demand_df.show(10)

# COMMAND ----------

# 47. SAVE DAILY SALES FOR POWER BI

daily_sales_pd = demand_df.toPandas()

daily_sales_pd.to_csv(
    "/Volumes/workspace/default/raw/daily_sales.csv",
    index=False
)

print("Daily sales file saved successfully.")
print("Rows:", len(daily_sales_pd))
print("Columns:", len(daily_sales_pd.columns))

# COMMAND ----------

# 48. CREATE AND SAVE CATEGORY SALES FOR POWER BI

category_sales = (
    demand_df
    .groupBy("cat_id")
    .agg(
        {"total_sales": "sum"}
    )
    .withColumnRenamed(
        "sum(total_sales)",
        "total_sales"
    )
    .orderBy(
        "total_sales",
        ascending=False
    )
)

category_sales_pd = category_sales.toPandas()

category_sales_pd.to_csv(
    "/Volumes/workspace/default/raw/category_sales.csv",
    index=False
)

print("Category sales file saved successfully.")
print("Rows:", len(category_sales_pd))
print("Columns:", len(category_sales_pd.columns))

print("\nCategory Sales:")
print(category_sales_pd)

# COMMAND ----------

# 49. CREATE AND SAVE STORE SALES FOR POWER BI

store_sales = (
    demand_df
    .groupBy("store_id", "state_id")
    .agg(
        {"total_sales": "sum"}
    )
    .withColumnRenamed(
        "sum(total_sales)",
        "total_sales"
    )
    .orderBy(
        "total_sales",
        ascending=False
    )
)

store_sales_pd = store_sales.toPandas()

store_sales_pd.to_csv(
    "/Volumes/workspace/default/raw/store_sales.csv",
    index=False
)

print("Store sales file saved successfully.")
print("Rows:", len(store_sales_pd))
print("Columns:", len(store_sales_pd.columns))

print("\nStore Sales:")
print(store_sales_pd)

# COMMAND ----------

# 50. CREATE AND SAVE MONTHLY SALES FOR POWER BI

monthly_sales = (
    demand_df
    .groupBy("year", "month")
    .agg(
        {"total_sales": "sum"}
    )
    .withColumnRenamed(
        "sum(total_sales)",
        "total_sales"
    )
    .orderBy(
        "year",
        "month"
    )
)

monthly_sales_pd = monthly_sales.toPandas()

monthly_sales_pd.to_csv(
    "/Volumes/workspace/default/raw/monthly_sales.csv",
    index=False
)

print("Monthly sales file saved successfully.")
print("Rows:", len(monthly_sales_pd))
print("Columns:", len(monthly_sales_pd.columns))

print("\nMonthly Sales:")
print(monthly_sales_pd)

# COMMAND ----------

# 51. CREATE AND SAVE PRODUCT SALES FOR POWER BI

from pyspark.sql.functions import sum

# Load sales validation data
sales_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sales_train_validation.csv")
)

# Identify daily sales columns
day_columns = [
    c for c in sales_df.columns
    if c.startswith("d_")
]

# Convert daily sales from wide format to long format
id_columns = [
    "id",
    "item_id",
    "dept_id",
    "cat_id",
    "store_id",
    "state_id"
]

stack_expr = ", ".join(
    [f"'{c}', `{c}`" for c in day_columns]
)

sales_long_df = sales_df.selectExpr(
    *id_columns,
    f"stack({len(day_columns)}, {stack_expr}) as (day_id, sales)"
)

# Calculate total sales by product
product_sales = (
    sales_long_df
    .groupBy("item_id")
    .agg(
        sum("sales").alias("total_sales")
    )
    .orderBy(
        "total_sales",
        ascending=False
    )
)

# Convert to Pandas
product_sales_pd = product_sales.toPandas()

# Save for Power BI
product_sales_pd.to_csv(
    "/Volumes/workspace/default/raw/product_sales.csv",
    index=False
)

print("Product sales file saved successfully.")
print("Rows:", len(product_sales_pd))
print("Columns:", len(product_sales_pd.columns))

print("\nTop 10 Products:")
print(product_sales_pd.head(10))

# COMMAND ----------

# 52. CREATE AND SAVE DEPARTMENT SALES FOR POWER BI

from pyspark.sql.functions import sum

# Load sales validation data
sales_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sales_train_validation.csv")
)

# Identify daily sales columns
day_columns = [
    c for c in sales_df.columns
    if c.startswith("d_")
]

# Convert daily sales from wide format to long format
id_columns = [
    "id",
    "item_id",
    "dept_id",
    "cat_id",
    "store_id",
    "state_id"
]

stack_expr = ", ".join(
    [f"'{c}', `{c}`" for c in day_columns]
)

sales_long_df = sales_df.selectExpr(
    *id_columns,
    f"stack({len(day_columns)}, {stack_expr}) as (day_id, sales)"
)

# Calculate total sales by department
department_sales = (
    sales_long_df
    .groupBy("dept_id")
    .agg(
        sum("sales").alias("total_sales")
    )
    .orderBy(
        "total_sales",
        ascending=False
    )
)

# Convert to Pandas
department_sales_pd = department_sales.toPandas()

# Save for Power BI
department_sales_pd.to_csv(
    "/Volumes/workspace/default/raw/department_sales.csv",
    index=False
)

print("Department sales file saved successfully.")
print("Rows:", len(department_sales_pd))
print("Columns:", len(department_sales_pd.columns))

print("\nDepartment Sales:")
print(department_sales_pd)

# COMMAND ----------

# 53. CREATE PRICE VS SALES DATA FOR POWER BI

from pyspark.sql.functions import col, sum, avg

# Load sales validation data
sales_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sales_train_validation.csv")
)

# Load calendar
calendar_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/calendar.csv")
)

# Load selling prices
price_df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv("/Volumes/workspace/default/raw/sell_prices.csv")
)

# Identify daily sales columns
day_columns = [
    c for c in sales_df.columns
    if c.startswith("d_")
]

# Product/store identifiers
id_columns = [
    "id",
    "item_id",
    "dept_id",
    "cat_id",
    "store_id",
    "state_id"
]

# Convert sales from wide format to long format
stack_expr = ", ".join(
    [f"'{c}', `{c}`" for c in day_columns]
)

sales_long_df = sales_df.selectExpr(
    *id_columns,
    f"stack({len(day_columns)}, {stack_expr}) as (day_id, sales)"
)

# Add date and Walmart week
sales_calendar_df = (
    sales_long_df
    .join(
        calendar_df.select(
            col("d").alias("day_id"),
            "date",
            "wm_yr_wk"
        ),
        "day_id",
        "left"
    )
)

# Join weekly selling price
sales_price_df = (
    sales_calendar_df
    .join(
        price_df.select(
            "store_id",
            "item_id",
            "wm_yr_wk",
            "sell_price"
        ),
        ["store_id", "item_id", "wm_yr_wk"],
        "left"
    )
)

# Aggregate to daily store-category level
price_sales_daily = (
    sales_price_df
    .groupBy(
        "date",
        "store_id",
        "state_id",
        "cat_id"
    )
    .agg(
        sum("sales").alias("total_sales"),
        avg("sell_price").alias("average_price")
    )
    .orderBy("date")
)

# Convert to Pandas
price_sales_pd = price_sales_daily.toPandas()

# Save Power BI-ready file
price_sales_pd.to_csv(
    "/Volumes/workspace/default/raw/price_sales_daily.csv",
    index=False
)

print("Price vs Sales file created successfully.")
print("Rows:", len(price_sales_pd))
print("Columns:", len(price_sales_pd.columns))

print("\nSample:")
print(price_sales_pd.head(10))

# COMMAND ----------

