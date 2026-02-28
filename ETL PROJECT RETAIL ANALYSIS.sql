CREATE TABLE fact_sales (
    invoice VARCHAR(20),
    stock_code VARCHAR(20),
    description TEXT,
    quantity INTEGER,
    price NUMERIC(10,2),
    revenue NUMERIC(12,2),
    customer_id INTEGER,
    country VARCHAR(50),
    invoice_date TIMESTAMP
);
truncate table fact_sales;

select count(*) as total_rows,
sum(revenue) as total_revenue,
count(distinct invoice) as total_order, 
count(distinct customer_id) as total_customer ,
sum(revenue)/count(distinct invoice) as AOV from fact_sales;


--monthly sales trend and precentage growth

SELECT 
    DATE_TRUNC('month', invoice_date) AS month,
    SUM(revenue) AS monthly_revenue,
    LAG(SUM(revenue)) OVER (ORDER BY DATE_TRUNC('month', invoice_date)) AS prev_month_revenue,
    ROUND(
        (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY DATE_TRUNC('month', invoice_date)))
        / LAG(SUM(revenue)) OVER (ORDER BY DATE_TRUNC('month', invoice_date)) * 100,
        2
    ) AS growth_percent
FROM fact_sales
GROUP BY month
ORDER BY month ;

--top 10 products

select stock_code, description, sum(revenue) as total_rev from fact_sales
group by description, stock_code
order by total_rev desc limit 10;

--top 10 customers

select customer_id, count(distinct invoice) as total_orders, sum(revenue) as total_revenue
from fact_sales
group by customer_id
order by total_revenue desc limit 10;

--Recency(last purchase date of cust),
--Frequency(total items purchased),Monetory(total money spent)
CREATE OR REPLACE VIEW vw_rfm_segment AS

WITH rfm_base AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(revenue) AS monetary,
        DATE_PART(
            'day',
            (SELECT MAX(invoice_date) FROM fact_sales) - MAX(invoice_date)
        ) AS recency
    FROM fact_sales
    GROUP BY customer_id
),

rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_base
),

rfm_segmented AS (
    SELECT *,
        CASE 
            WHEN r_score = 1 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'At Risk'
            WHEN r_score = 5 AND f_score = 1 THEN 'Lost Customers'
            ELSE 'Potential'
        END AS segment
    FROM rfm_scores
)

SELECT 
    segment,
    COUNT(*) AS customers,
    SUM(monetary) AS total_revenue,
    ROUND(
        SUM(monetary) * 100.0 
        / SUM(SUM(monetary)) OVER (),
        2
    ) AS revenue_percentage
FROM rfm_segmented
GROUP BY segment
ORDER BY total_revenue DESC;



--cohort analysis..
DROP VIEW IF EXISTS vw_cohort_retention;
CREATE OR REPLACE VIEW vw_cohort_retention AS

WITH first_purchase AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(invoice_date)) AS cohort_month
    FROM fact_sales
    GROUP BY customer_id
),

cohort_data AS (
    SELECT 
        f.customer_id,
        fp.cohort_month,
        DATE_PART(
            'month',
            AGE(DATE_TRUNC('month', f.invoice_date), fp.cohort_month)
        ) AS month_number
    FROM fact_sales f
    JOIN first_purchase fp
        ON f.customer_id = fp.customer_id
),

cohort_counts AS (
    SELECT 
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS customers
    FROM cohort_data
    GROUP BY cohort_month, month_number
),

cohort_retention AS (
    SELECT 
        cohort_month,
        month_number,
        ROUND(
            customers * 100.0 /
            FIRST_VALUE(customers) OVER (
                PARTITION BY cohort_month
                ORDER BY month_number
            ),
            2
        ) AS retention_percentage
    FROM cohort_counts
)

SELECT 
    cohort_month,
    month_number,
    retention_percentage
FROM cohort_retention
ORDER BY cohort_month, month_number;