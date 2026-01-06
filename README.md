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
## Phase 1 — Data Validation & Baseline Time Structure

### Objective
Ensure the dataset is **fit for time series analysis** and define a **baseline time granularity** before performing trend, seasonality, or intervention analysis.

---

### Analytical Focus
This phase aims to:
- Validate whether the data can be **trusted** for time series analysis  
- Identify the appropriate **time aggregation level**  
- Understand the dataset at a **high level** before drawing conclusions  

---

### Data Validation Checks
- Verified **one row per store per date** with no duplicate records  
- Confirmed **no NULL values** in key analytical fields (`sales`, `store`, `date`, `promo`, `open`)  
- Checked **overall date continuity**, confirming approximately **2.5 years** of data  

---

### Store-Level Completeness
- Assessed **data availability per store**
- Identified potential **store-specific date gaps**
- Flagged completeness issues for awareness (**not corrected in this phase**)  

---

### Zero-Sales Behavior
- Identified **zero-sales observations** in the dataset  
- Observed cases where `sales = 0` even when `open = 1`  
- Treated these as **structural or business behavior**, not data errors  

---

### Baseline Time Structure
- Recognized **daily sales data** as noisy for baseline analysis  
- Selected **weekly aggregation** as the baseline timeline  
- Noted likely **intra-week (day-of-week) seasonality**, deferred to later phases  

---

### Exploratory Baseline Behavior (Non-Confirmatory)
- Inspected **weekly sales levels** and **rolling averages**  
- Compared **early vs late periods** to identify directional signals  
- Examined **rolling variability** to understand volatility patterns  

---

### Candidate Seasonality Detection
- Grouped weekly sales by **week-of-year**
- Identified **potential repeating high and low weeks**
- Treated seasonality as **indicative**, not confirmed  

---

### Key Takeaway
Phase 1 establishes **data reliability** and defines a **weekly baseline time structure**, while identifying **potential trend and seasonality signals** that are validated in later phases.


## Phase 2 — Trend Robustness & Validation

### Objective
Validate whether the aggregate sales patterns observed in Phase 1 represent **true underlying behavior** or are driven by **extreme conditions**.

---

### Analytical Focus
This phase aims to:
- Test whether **store closures** explain low-sales weeks  
- Check if aggregate trends are driven by **a few extreme weeks**  
- Confirm whether the **weekly baseline** is robust enough to proceed  

---

### Key Checks Performed
- Compared **weekly sales vs closure rates** to assess operational impact  
- Evaluated **mean vs median weekly sales** to detect outlier dominance  
- Computed **trimmed averages** by excluding extreme high/low weeks  

---

### Key Takeaway
Closures explain some low-performing weeks, but **do not fully drive aggregate behavior**.  
Mean, median, and trimmed averages are closely aligned, indicating that observed trends are **not dominated by extreme weeks**.  
The **weekly baseline is validated** for further analysis.


## Phase 3 — Store-Level Segmentation

### Objective
Assess whether aggregate trends and seasonality reflect **broad-based store behavior** or mask **heterogeneity across individual stores**.

---

### Analytical Focus
This phase aims to:
- Determine if the **overall upward trend** is shared by most stores  
- Identify **store-level trend differences** (growing, flat, declining)  
- Measure the **strength of seasonality** at the individual store level  

---

### Key Analyses Performed
- Compared **early vs late average weekly sales** for each store  
- Segmented stores into **upward, flat, and downward** trend categories using tolerance bands  
- Computed **seasonality strength** per store using week-of-year variability  

---

### Key Takeaway
Most stores follow the aggregate upward trend, indicating **broad-based growth rather than concentration in a few stores**.  
However, meaningful **heterogeneity exists** in both trend magnitude and seasonality strength across stores, motivating store-level analysis in later phases.


## Phase 4 — Intervention Analysis (Promotions & Holidays)

### Objective
Quantify how **promotions and holidays** create deviations from baseline sales and determine whether observed effects persist after **controlling for seasonality**.

---

### Analytical Focus
This phase aims to:
- Measure **promo vs non-promo** sales differences  
- Separate **promo effects** from **seasonal timing effects**  
- Neutralize baseline behavior to estimate **true promo lift**  
- Examine **heterogeneity** in promo effectiveness across stores  

---

### Key Analyses Performed
- Compared **average weekly sales** during promo vs non-promo weeks  
- Controlled for seasonality by comparing **promo and non-promo weeks within the same store and week-of-year**  
- Constructed a **baseline expectation** and analyzed **residual sales (actual − expected)**  
- Evaluated **store-level promo lift** and its variation across trend and seasonality segments  

---

### Key Takeaway
Promotions are associated with **systematically higher sales**, even after controlling for seasonality and baseline behavior.  
However, the **magnitude of promo lift varies substantially across stores**, highlighting the importance of store-level targeting rather than uniform promotional strategies.


## Phase 5 — Synthesis & Business KPIs

### Objective
Translate the analytical results into **business-ready KPIs** and summaries that support **decision-making**.

---

### Analytical Focus
This phase aims to:
- Summarize **promo impact** using time-series–aware KPIs  
- Quantify **consistency and variability** of promo effects across stores  
- Produce **final tables** suitable for README, slides, or interviews  

---

### Key Outputs
- **Average weekly promo lift** after baseline and seasonality control  
- **Percentage of stores with positive promo impact**  
- **Minimum, maximum, and average promo lift** across stores  
- Comparison of **Promo**, **Holiday**, and **Promo + Holiday** effects  
- **Top and bottom stores** ranked by promo effectiveness  

---

### Key Takeaway
Time-series analysis of baseline and interventions was distilled into **clear KPIs**, showing that promotions generally increase sales but with **substantial store-level heterogeneity**.  
These KPIs enable **targeted promotional decisions** rather than one-size-fits-all strategies.


## Phase 6 — Validation, Assumptions & Limitations

### Objective
Acknowledge **analytical assumptions**, identify **limitations**, and clarify what the analysis **can and cannot conclude**.

---

### Validation Notes
- Promo effects are **associational**, not strictly causal  
- Baseline construction assumes **non-promo, non-holiday weeks** represent typical demand  
- Weekly aggregation smooths noise but may hide **short-term intra-week effects**  

---

### Limitations
- No price or margin data to assess **profitability of promotions**
- No experimental or causal design (e.g., A/B test, DiD)
- External factors (competition, weather, local events) not included
- Holiday effects treated structurally, not modeled independently

---

### Future Extensions
- Difference-in-Differences or causal inference methods
- Store clustering before promotion design
- Modeling promo duration and lag effects
- Forecasting under alternative promotion strategies

## Phase 7 — Final Packaging & Project Overview

### Repository Structure
- `sql/` — Phase-wise SQL analysis (Phases 1–5)
- `README.md` — Business narrative and insights

---

### Tech Stack
- **SQL (MySQL 8+)**
- Window functions and CTEs
- Time-series aggregation and decomposition logic

---

### How to Use This Project
- Review **Phase 0–1** to understand business framing and data reliability
- Follow **Phases 2–4** to see trend validation, segmentation, and intervention analysis
- Refer to **Phase 5** for final KPIs and business-ready insights

---

### Project Summary
This project demonstrates an **end-to-end time series analysis in SQL**, moving from raw transactional data to **validated trends**, **controlled intervention effects**, and **actionable KPIs**.  
It is designed to mirror how time-series analysis is conducted in **real-world business analytics**.



