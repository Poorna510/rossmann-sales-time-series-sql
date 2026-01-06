# Rossmann Sales Time Series Analysis (SQL)

SQL-based time series analysis on the Rossmann sales dataset, focusing on **trend**, **seasonality**, and **promotion impact** using a **business-driven analytical approach**.

---

## Phase 0 — Business Framing

### Objective
The objective of this project is to analyze how **store sales evolve over time** and to understand the impact of **promotions and holidays** on **baseline sales behavior**.

---

### Dataset Overview (Initial Screening)
- The dataset contains **daily sales data for individual stores**.
- Each row represents sales activity for **one store on one day**.
- Each store forms an **independent time series**, making this a **multiple time series dataset**.
- The primary metric of interest is **Sales**, used as a **proxy for revenue**.
- The time dimension is **calendar-based and evenly spaced**.
- The dataset spans approximately **two and a half years overall**, with **data completeness to be validated at the store level**.

---

### Analytical Focus
The analysis aims to uncover:
- **Trends** in sales over time  
- **Seasonality** and repeating calendar patterns  
- **Variability and volatility** in sales behavior  
- **Anomalies**, including sudden shifts, trend breaks, and disruptions  
- Differences between **aggregate behavior** and **store-level behavior**

---

### Business Questions
- Is sales performance **improving, declining, or stable** over time?
- Do sales exhibit **repeating seasonal patterns** across weeks or months?
- How **volatile** are sales over time for individual stores?
- Are there **sudden shifts or disruptions** in sales behavior?
- How do **promotions and holidays** affect sales relative to the **baseline**?
- Do all stores respond **similarly**, or is the impact **store-specific**?

---
