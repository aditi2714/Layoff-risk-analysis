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

