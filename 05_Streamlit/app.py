import streamlit as st
import pandas as pd

# Page Configuration
st.set_page_config(
    page_title="M5 Retail Sales Forecasting",
    layout="wide"
)

# Dashboard Title
st.title("Retail Sales Forecasting & Demand Prediction")

st.write(
    "M5 Retail Sales Forecasting project dashboard"
)


# =========================================================
# LOAD DATA
# =========================================================

daily_sales = pd.read_csv("data/daily_sales.csv")
forecast = pd.read_csv("data/m5_forecast_results.csv")
category_sales = pd.read_csv("data/category_sales.csv")
store_sales = pd.read_csv("data/store_sales.csv")
monthly_sales = pd.read_csv("data/monthly_sales.csv")
price_sales = pd.read_csv("data/price_sales_daily.csv")
product_sales = pd.read_csv("data/product_sales.csv")
department_sales = pd.read_csv("data/department_sales.csv")


# =========================================================
# FILTERS
# =========================================================

st.sidebar.header("Filters")

state_options = ["All"] + sorted(
    daily_sales["state_id"].dropna().unique().tolist()
)

selected_state = st.sidebar.selectbox(
    "Select State",
    state_options
)

store_options = ["All"] + sorted(
    daily_sales["store_id"].dropna().unique().tolist()
)

selected_store = st.sidebar.selectbox(
    "Select Store",
    store_options
)

category_options = ["All"] + sorted(
    daily_sales["cat_id"].dropna().unique().tolist()
)

selected_category = st.sidebar.selectbox(
    "Select Category",
    category_options
)


# Apply Filters

filtered_daily_sales = daily_sales.copy()

if selected_state != "All":
    filtered_daily_sales = filtered_daily_sales[
        filtered_daily_sales["state_id"] == selected_state
    ]

if selected_store != "All":
    filtered_daily_sales = filtered_daily_sales[
        filtered_daily_sales["store_id"] == selected_store
    ]

if selected_category != "All":
    filtered_daily_sales = filtered_daily_sales[
        filtered_daily_sales["cat_id"] == selected_category
    ]


# =========================================================
# PREPARE KPI VALUES
# =========================================================

total_sales = filtered_daily_sales["total_sales"].sum()

total_stores = filtered_daily_sales["store_id"].nunique()

total_categories = filtered_daily_sales["cat_id"].nunique()

forecasted_sales = forecast["predicted_sales"].sum()


# =========================================================
# KPI CARDS
# =========================================================

st.subheader("Key Performance Indicators")

col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric(
        "Total Units Sold",
        f"{total_sales / 1_000_000:.1f}M"
    )

with col2:
    st.metric(
        "Total Stores",
        total_stores
    )

with col3:
    st.metric(
        "Total Categories",
        total_categories
    )

with col4:
    st.metric(
        "Forecasted Sales",
        f"{forecasted_sales:,.0f}"
    )


# =========================================================
# DAILY SALES TREND
# =========================================================

st.subheader("Daily Sales Trend")

filtered_daily_sales["date"] = pd.to_datetime(
    filtered_daily_sales["date"]
)

daily_trend = (
    filtered_daily_sales
    .groupby("date", as_index=False)["total_sales"]
    .sum()
    .set_index("date")
)

st.line_chart(daily_trend)


# =========================================================
# SALES BY CATEGORY
# =========================================================

st.subheader("Sales by Category")

filtered_category_sales = (
    filtered_daily_sales
    .groupby("cat_id")["total_sales"]
    .sum()
    .sort_values(ascending=False)
)

st.bar_chart(filtered_category_sales)


# =========================================================
# STORE PERFORMANCE
# =========================================================

st.subheader("Store-wise Sales Performance")

filtered_store_sales = (
    filtered_daily_sales
    .groupby("store_id")["total_sales"]
    .sum()
    .sort_values(ascending=False)
)

st.bar_chart(filtered_store_sales)


# =========================================================
# MONTHLY SALES TREND
# =========================================================

st.subheader("Monthly Sales Trend")

filtered_monthly_sales = filtered_daily_sales.copy()

filtered_monthly_sales["date"] = pd.to_datetime(
    filtered_monthly_sales["date"]
)

monthly_chart = (
    filtered_monthly_sales
    .groupby(
        filtered_monthly_sales["date"].dt.to_period("M")
    )["total_sales"]
    .sum()
)

monthly_chart.index = monthly_chart.index.astype(str)

st.line_chart(monthly_chart)


# =========================================================
# EVENT DAY VS NORMAL DAY
# =========================================================

st.subheader("Sales During Events vs Normal Days")

event_1 = (
    filtered_daily_sales["event_name_1"]
    .fillna("")
    .astype(str)
    .str.strip()
)

event_2 = (
    filtered_daily_sales["event_name_2"]
    .fillna("")
    .astype(str)
    .str.strip()
)

filtered_daily_sales["Day Type"] = (
    ((event_1 != "") | (event_2 != ""))
    .map({
        True: "Event Day",
        False: "Normal Day"
    })
)

event_summary = (
    filtered_daily_sales
    .groupby("Day Type")["total_sales"]
    .sum()
)

st.bar_chart(event_summary)


# =========================================================
# ACTUAL VS FORECASTED SALES
# =========================================================

st.subheader("Actual vs Forecasted Sales")

forecast["date"] = pd.to_datetime(
    forecast["date"]
)

actual_forecast = (
    forecast
    .groupby("date")[["actual_sales", "predicted_sales"]]
    .sum()
    .sort_index()
)

st.line_chart(actual_forecast)


# =========================================================
# FORECAST VARIANCE BY CATEGORY
# =========================================================

st.subheader("Forecast Variance by Category")

forecast["forecast_variance"] = (
    forecast["predicted_sales"]
    - forecast["actual_sales"]
)

variance_by_category = (
    forecast
    .groupby("cat_id")["forecast_variance"]
    .sum()
    .sort_values()
)

st.bar_chart(variance_by_category)


# =========================================================
# MODEL EVALUATION
# =========================================================

st.subheader("Model Evaluation")

evaluation = pd.read_csv(
    "data/m5_model_evaluation.csv"
)

eval_col1, eval_col2 = st.columns(2)

with eval_col1:
    st.metric(
        "Mean Absolute Error (MAE)",
        f"{evaluation['MAE'].iloc[0]:,.2f}"
    )

with eval_col2:
    st.metric(
        "Root Mean Squared Error (RMSE)",
        f"{evaluation['RMSE'].iloc[0]:,.2f}"
    )


# =========================================================
# PRICE VS SALES
# =========================================================

st.subheader("Price vs Sales")

price_sales["date"] = pd.to_datetime(
    price_sales["date"]
)

price_sales_clean = price_sales.dropna(
    subset=["average_price", "total_sales"]
)

st.scatter_chart(
    price_sales_clean,
    x="average_price",
    y="total_sales"
)


# =========================================================
# TOP 10 PRODUCTS
# =========================================================

st.subheader("Top 10 Products by Sales")

top_products = (
    product_sales
    .sort_values("total_sales", ascending=False)
    .head(10)
    .set_index("item_id")
)

st.bar_chart(
    top_products["total_sales"]
)


# =========================================================
# DEPARTMENT PERFORMANCE
# =========================================================

st.subheader("Sales by Department")

department_chart = (
    department_sales
    .sort_values("total_sales", ascending=False)
    .set_index("dept_id")
)

st.bar_chart(
    department_chart["total_sales"]
)


# =========================================================
# DATA PREVIEW
# =========================================================

st.subheader("Daily Sales Data")

st.write(
    "Rows:",
    len(daily_sales)
)

st.write(
    "Columns:",
    len(daily_sales.columns)
)

st.dataframe(
    daily_sales.head(10)
)