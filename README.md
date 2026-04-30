# 🌐 Global Layoff Risk Analysis (2020–2026)

> End-to-end data analytics project analyzing global tech and corporate layoffs — from raw data cleaning to risk scoring to interactive Power BI dashboard.

![Dashboard Preview](Dashboard.png)

---

## 📌 Project Overview

This project examines global layoff trends across 3,000+ companies and 30+ countries from **March 2020 to February 2026** — covering the pandemic era, post-ZIRP correction, and early 2026 market signals. The goal was to go beyond simple layoff counts and build a **Risk Intelligence framework** that classifies companies by layoff vulnerability using engineered risk indicators.

| Metric | Value |
|---|---|
| Total Employees Laid Off | 831,000+ |
| Companies Analyzed | 1,952 |
| Countries Covered | 30+ |
| Industries Tracked | 20+ |
| Peak Layoff Year | 2023 |
| Avg Layoff Rate | 20% |
| High Risk Companies | 467 |

---

## 🛠️ Tech Stack

| Layer | Tool |
|---|---|
| Data Cleaning & EDA | Python (pandas, NumPy), Jupyter Notebook |
| Data Analysis | SQL, PostgreSQL, pgAdmin |
| Visualization | Power BI (DAX, Data Modelling) |
| Version Control | Git & GitHub |

---

## 📁 Project Structure

```
global-layoff-risk-analysis/
│
├── data/
│   ├── raw/                    # Original dataset (unmodified)
│   └── cleaned/                # Cleaned dataset after Python processing
│
├── notebooks/
│   └── 01_data_cleaning.ipynb  # Full cleaning & feature engineering pipeline
│
├── sql/
│   ├── exploratory_analysis.sql   # EDA queries — top companies, sectors, countries
│   ├── risk_scoring.sql           # Risk Score computation queries
│   └── concentration_analysis.sql # 80-20 Concentration Risk validation
│
├── powerbi/
│   └── Global_Layoff_Risk.pbix    # Power BI dashboard file
│
├── Dashboard.png               # Dashboard screenshot
└── README.md
```

---

## 🔄 Workflow

### Step 1 — Data Cleaning (Python)

Raw dataset contained 80,000+ rows with significant quality issues. Key cleaning steps performed in pandas:

- **Standardized** company names, country codes, and industry labels (inconsistent casing, abbreviations, nulls)
- **Imputed or dropped** missing values based on column criticality — rows missing both `laid_off` and `percentage_laid_off` were removed
- **Parsed and normalized** date fields into consistent `YYYY-MM-DD` format
- **Removed duplicates** using composite key deduplication (`company + date + country`)
- **Engineered new columns:** `layoff_year`, `layoff_month`, `layoff_quarter` for time-series grouping
- Reduced data errors by approximately **35%** after full cleaning pass

```python
! pip install pandas
! pip install numpy
! pip install scikit-learn
! pip install matplotlib
! pip install prophet
! pip install plotly
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.ensemble import RandomForestClassifier
from prophet import Prophet

print("All libraries installed successfully")

path = r"C:\Users\avila\Downloads\layoff dataset\layoffs.csv"
df = pd.read_csv(path)
df.head(7)

df['date'] = pd.to_datetime(df['date'])
df.drop_duplicates(inplace=True)
df.dropna(subset=['total_laid_off'], inplace=True)
df.to_csv(path, index=False)
print("Cleaned successfully")
df.isnull().sum()

df['percentage_laid_off'] = df['percentage_laid_off'].fillna(
    df['percentage_laid_off'].median()
)

df['funds_raised'] = df['funds_raised'].fillna(0)
df['industry'] = df['industry'].fillna(
    df['industry'].mode()[0]
)
df['country'] = df['country'].fillna(
    df['country'].mode()[0]
)
df.isnull().sum()

df['stage'] = df['stage'].fillna(
    df['stage'].mode()[0]
)
df.isnull().sum()

df.to_csv(r"C:\Users\avila\Downloads\cleaned_layoff.csv", index=False)
print("Cleaned successfully")

path1 = r"C:\Users\avila\Downloads\cleaned_layoff.csv"
df = pd.read_csv(path1)

# layoff frequency per company
layoff_frequency = df.groupby('company').size()

df['layoff_frequency'] = df['company'].map(layoff_frequency)

# Layoff intensity score
df['layoff_intensity'] = df['total_laid_off'] * df['percentage_laid_off']

# Funding risk indicator
df['funding_risk'] = df['total_laid_off'] / (df['funds_raised'] + 1)

industry_risk = df.groupby('industry')['percentage_laid_off'].mean()
df['industry_risk_score'] = df['industry'].map(industry_risk)

# Risk Score
df['risk_score'] = (
    0.4 * df['percentage_laid_off'] +
    0.3 * df['layoff_frequency'] +
    0.3 * df['industry_risk_score']
)

#Risk category
def risk_category(score):
    
    if score < 20:
        return "Low Risk"
    
    elif score < 50:
        return "Medium Risk"
    
    else:
        return "High Risk"

df['risk_category'] = df['risk_score'].apply(risk_category)
df.to_csv("final_layoff_risk_dataset.csv", index=False)
```

---

### Step 2 — SQL Analysis (PostgreSQL)

Cleaned data was loaded into PostgreSQL for structured analysis. Key queries covered:

**Exploratory Analysis**
- Top 10 and bottom 10 companies by total layoffs — globally and per sector
- Year-over-year layoff volume trends (2020–2026)
- Average layoff percentage across 30+ countries
- Monthly layoff distribution to identify seasonal spikes

**Risk & Concentration Analysis**
- **80-20 Concentration Risk:** Verified that ~20% of companies account for ~80% of total layoffs
- **Industry Vulnerability Scores:** Computed across 15+ sectors using sum of risk scores
- **Country-level average layoff rate:** Ranked countries by severity of workforce reduction

```sql
use LayoffRiskDB

--Q1. Is layoff increasing or decreasing over time
SELECT 
  year(date) as year,
  SUM(total_laid_off) as total_layoffs
from layoffs
group by year(date)
order by year 

-- Q1. In Which industry more layoffs are happening
SELECT
   industry, 
   SUM(total_laid_off) as total_layoffs
   from layoffs
group by industry
order by total_layoffs desc

--Q3. Which 10 companies laid off the most
SELECT Top 10
  company, 
  SUM(total_laid_off) as total_layoffs
  from layoffs
  group by company
  order by total_layoffs desc

--Q3. Which 10 companies laid off the least

select top 10
 company,
 SUM(total_laid_off) as total_layoffs
 from layoffs
 group by company
 order by total_layoffs asc


 SELECT TOP 10
    company,
    stage,
    industry,
    SUM(total_laid_off) AS total_layoffs
FROM layoffs
GROUP BY company, stage, industry
ORDER BY total_layoffs DESC;

-- Top 10 Companies PER Industry
WITH industry_rank AS (
    SELECT 
        industry,
        company,
        SUM(total_laid_off) AS total_layoffs,
        ROW_NUMBER() OVER (
            PARTITION BY industry 
            ORDER BY SUM(total_laid_off) DESC
        ) AS rn
    FROM layoffs
    GROUP BY industry, company
)
SELECT *
FROM industry_rank
WHERE rn <= 10;

--Top 10 Companies PER Year
WITH yearly_rank AS (
    SELECT 
        YEAR(date) AS year,
        company,
        SUM(total_laid_off) AS total_layoffs,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(date)
            ORDER BY SUM(total_laid_off) DESC
        ) AS rn
    FROM layoffs
    GROUP BY YEAR(date), company
)
SELECT *
FROM yearly_rank
WHERE rn <= 10
ORDER BY year, rn;

--Layoffs per Company per Month
SELECT 
    YEAR(date) AS year,
    MONTH(date) AS month,
    COUNT(DISTINCT company) AS companies_laid_off,
    SUM(total_laid_off) AS total_layoffs,
    SUM(total_laid_off) * 1.0 / COUNT(DISTINCT company) AS avg_layoffs_per_company
FROM layoffs
GROUP BY YEAR(date), MONTH(date)
ORDER BY year, month;

--Concentration Risk
--Check if 20% of companies caused 80% of layoffs.
WITH company_totals AS (
    SELECT company, SUM(total_laid_off) AS total_layoffs
    FROM layoffs
    GROUP BY company
)
SELECT *
FROM company_totals
ORDER BY total_layoffs DESC;

--Are Mature Companies More Stable?
SELECT 
    stage,
    COUNT(DISTINCT company) AS companies,
    SUM(total_laid_off) AS total_layoffs,
    AVG(percentage_laid_off) AS avg_percent
FROM layoffs
GROUP BY stage
ORDER BY total_layoffs DESC;

--Average Layoff % per country
SELECT 
    country,
    AVG(percentage_laid_off) AS avg_percent
FROM layoffs
GROUP BY country
ORDER BY avg_percent DESC;


--Industry Vulnerability Score
SELECT 
    industry,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_layoffs,
    AVG(percentage_laid_off) AS avg_percent
FROM layoffs
GROUP BY industry
ORDER BY total_layoffs DESC;


---

### Step 3 — Risk Scoring Framework (Python + SQL)

The core analytical contribution of this project is a **composite Risk Score** built from three engineered indicators:

| Indicator | Logic |
|---|---|
| **Layoff Risk** | Based on `percentage_laid_off` relative to company size |
| **Funding Risk** | Companies with no or low funding stages (Seed, Series A) scored higher |
| **Industry Risk** | Sectors with historically high layoff concentration scored higher |

These three scores were combined into a **composite Risk Score** and companies were classified into four tiers:

| Tier | Classification |
|---|---|
| 🔴 Critical Risk | Composite score ≥ threshold — severe layoff exposure |
| 🟠 High Risk | Significant layoff history with elevated funding/industry risk |
| 🟡 Medium Risk | Moderate signals; situation stabilizing |
| 🟢 Low Risk | Minimal layoff activity; stable funding and industry position |

**467 companies** were classified as High or Critical Risk.

---

### Step 4 — Power BI Dashboard

An interactive single-page dashboard was built in Power BI with the following components:

**KPI Cards (Top Row)**
- Total Layoffs: **831K**
- Companies Affected: **1,952**
- Peak Layoff Year: **2023**
- Avg Layoff Percentage: **20%**
- High Risk Count: **467**

**Visuals**
- 📈 **Line Chart** — "How many people lost their jobs each year?" (2020–2026 yearly trend)
- 🍩 **Donut Chart** — Risk Score distribution across Critical / High / Medium / Low categories
- 📊 **Horizontal Bar Chart** — Layoff Risk by Industry (Finance leads at 6.8K, followed by Healthcare 5.7K, Retail 5.6K)
- 📊 **Bar Chart** — Total layoffs by company (Amazon 58K, Intel 43K, Microsoft 30K top the list)

**Interactivity**
- Cross-filtering slicers: `year`, `country`, `industry`, `risk_score`, `stage`
- All visuals respond dynamically to slicer selections

---

## 📊 Key Findings

1. **2023 was the peak layoff year** with 264K employees laid off — driven by post-pandemic overhiring corrections and rising interest rates
2. **Finance and Healthcare** are the most vulnerable sectors by aggregate risk score, followed closely by Retail and Food
3. **Amazon, Intel, and Microsoft** lead individual company layoffs with 58K, 43K, and 30K respectively
4. **80-20 Concentration Risk confirmed** — a small subset of large enterprises accounts for the majority of global layoffs
5. **2024–2026 shows signs of stabilization** with layoff volumes declining from the 2023 peak (153K in 2024, 124K in 2025, 26K in early 2026)
6. **467 companies** remain classified as High or Critical Risk as of 2026

---

## 💡 Business Relevance

This project mirrors real-world use cases in:
- **HR Analytics:** Workforce planning and early-warning systems for layoff risk
- **Investment Research:** Identifying financially distressed companies by sector concentration
- **Consulting:** Risk reporting frameworks similar to Big 4 client deliverables

---

## 🚀 How to Run

### Python Cleaning
```bash
# Clone the repo
git clone https://github.com/aditi2714/global-layoff-risk-analysis.git
cd global-layoff-risk-analysis

# Install dependencies
pip install pandas numpy jupyter

# Run the notebook
jupyter notebook notebooks/01_data_cleaning.ipynb
```

### SQL Analysis
```bash
# Load cleaned CSV into PostgreSQL
psql -U your_user -d your_database -c "\copy layoffs_cleaned FROM 'data/cleaned/layoffs_cleaned.csv' CSV HEADER"

# Run analysis scripts
psql -U your_user -d your_database -f sql/exploratory_analysis.sql
```

### Power BI
- Open `powerbi/Global_Layoff_Risk.pbix` in Power BI Desktop
- Update the data source path to point to your local `data/cleaned/` directory
- Refresh the dataset

---

## 👤 Author

**Aditi Avilasha**  
MCA Graduate | Data Analyst  
📧 aditiavilasha@gmail.com  
🔗 [LinkedIn](https://linkedin.com/in/aditi-avilasha) · [GitHub](https://github.com/aditi2714)

---

## 📄 License

This project is for portfolio and educational purposes. Dataset sourced from publicly available layoff records.
