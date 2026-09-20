import streamlit as st

st.set_page_config(
    page_title="Retail Sales Forecasting",
    layout="wide"
)

st.title("Retail Sales Forecasting & Demand Prediction")

st.write(
    "M5 Retail Sales Forecasting project dashboard"
)

st.subheader("Project Overview")

st.write(
    "This application presents retail sales analysis, "
    "store and category performance, and demand forecasting "
    "insights from the M5 dataset."
)

col1, col2, col3 = st.columns(3)

with col1:
    st.metric("Industry", "Retail")

with col2:
    st.metric("Business Function", "Sales / Operations")

with col3:
    st.metric("Analysis Type", "Predictive")

st.success("Streamlit application created successfully.")
