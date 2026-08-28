
/* ---------------------------------------------------------
   1. TOP-LINE KPIs
--------------------------------------------------------- */
SELECT
    COUNT(*)                                            AS total_orders,
    SUM(net_revenue)                                    AS total_revenue,
    SUM(profit)                                         AS total_profit,
    CAST(SUM(profit) * 100.0 / SUM(net_revenue) AS DECIMAL(5,2)) AS profit_margin_pct,
    CAST(AVG(net_revenue) AS DECIMAL(10,2))             AS avg_order_value
FROM dbo.Sales_Analysis;
GO



/* ---------------------------------------------------------
   2. MONTHLY REVENUE TREND (with month-over-month growth)
--------------------------------------------------------- */
WITH monthly AS (
    SELECT
        FORMAT(order_date, 'yyyy-MM')  AS sales_month,
        SUM(net_revenue)               AS revenue
    FROM dbo.Sales_Analysis
    GROUP BY FORMAT(order_date, 'yyyy-MM')
)
SELECT
    sales_month,
    revenue,
    CAST(
        (revenue - LAG(revenue) OVER (ORDER BY sales_month)) * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY sales_month), 0)
    AS DECIMAL(6,2)) AS mom_growth_pct
FROM monthly
ORDER BY sales_month;
GO

SELECT* from dbo.Sales_Analysis;

/* ---------------------------------------------------------
   3. YEAR-OVER-YEAR REVENUE COMPARISON
--------------------------------------------------------- */
SELECT
    YEAR(order_date)   AS sales_year,
    SUM(net_revenue)   AS revenue,
    SUM(profit)        AS profit
FROM dbo.Sales_Analysis
GROUP BY YEAR(order_date)
ORDER BY sales_year;
GO


/* ---------------------------------------------------------
   4. REVENUE & PROFIT BY REGION
--------------------------------------------------------- */
SELECT
    region,
    COUNT(*)                                             AS orders,
    SUM(net_revenue)                                      AS revenue,
    SUM(profit)                                           AS profit,
    CAST(SUM(profit) * 100.0 / SUM(net_revenue) AS DECIMAL(5,2)) AS margin_pct
FROM dbo.Sales_Analysis
GROUP BY region
ORDER BY revenue DESC;
GO



/* ---------------------------------------------------------
   5. TOP 10 PRODUCTS BY REVENUE
--------------------------------------------------------- */
SELECT TOP 10
    category,
    product,
    SUM(quantity)      AS units_sold,
    SUM(net_revenue)   AS revenue,
    SUM(profit)        AS profit
FROM dbo.Sales_Analysis
GROUP BY category, product
ORDER BY revenue DESC;
GO


/* ---------------------------------------------------------
   6. CATEGORY PERFORMANCE
--------------------------------------------------------- */
SELECT
    category,
    SUM(net_revenue)                                                    AS revenue,
    SUM(profit)                                                         AS profit,
    CAST(SUM(profit) * 100.0 / SUM(net_revenue) AS DECIMAL(5,2))        AS margin_pct,
    CAST(SUM(net_revenue) * 100.0 /
        (SELECT SUM(net_revenue) FROM dbo.Sales_Analysis) AS DECIMAL(5,2))       AS pct_of_total_revenue
FROM dbo.Sales_Analysis
GROUP BY category
ORDER BY revenue DESC;
GO


/* ---------------------------------------------------------
   7. TOP 15 CUSTOMERS BY LIFETIME REVENUE
--------------------------------------------------------- */
SELECT TOP 15
    customer_id,
    customer_segment  AS segment,
    region,
    COUNT(*)          AS orders,
    SUM(net_revenue)  AS lifetime_revenue
FROM dbo.Sales_Analysis
GROUP BY customer_id, customer_segment, region
ORDER BY lifetime_revenue DESC;
GO


/* ---------------------------------------------------------
   8. SALES CHANNEL MIX
--------------------------------------------------------- */
SELECT
    sales_channel,
    COUNT(*)                                                       AS orders,
    SUM(net_revenue)                                                AS revenue,
    CAST(AVG(net_revenue) AS DECIMAL(10,2))                        AS avg_order_value,
    CAST(SUM(net_revenue) * 100.0 /
        (SELECT SUM(net_revenue) FROM dbo.Sales_Analysis) AS DECIMAL(5,2))  AS pct_of_revenue
FROM dbo.Sales_Analysis
GROUP BY sales_channel
ORDER BY revenue DESC;
GO


/* ---------------------------------------------------------
   9. SALES REP LEADERBOARD
--------------------------------------------------------- */
SELECT
    sales_rep,
    COUNT(*)           AS orders,
    SUM(net_revenue)   AS revenue,
    SUM(profit)        AS profit,
    RANK() OVER (ORDER BY SUM(net_revenue) DESC) AS revenue_rank
FROM dbo.Sales_Analysis
GROUP BY sales_rep
ORDER BY revenue DESC;
GO


/* ---------------------------------------------------------
   10. CUSTOMER SEGMENT ANALYSIS
--------------------------------------------------------- */
SELECT
    customer_segment,
    COUNT(DISTINCT customer_id)                                     AS customers,
    COUNT(*)                                                        AS orders,
    SUM(net_revenue)                                                 AS revenue,
    CAST(SUM(net_revenue) / COUNT(DISTINCT customer_id) AS DECIMAL(10,2)) AS revenue_per_customer
FROM dbo.Sales_Analysis
GROUP BY customer_segment
ORDER BY revenue DESC;
GO


/* ---------------------------------------------------------
   11. DISCOUNT IMPACT ANALYSIS
--------------------------------------------------------- */
SELECT
    CASE
        WHEN TRY_CAST(REPLACE(discount_pct, '%', '') AS FLOAT) = 0
            THEN 'No Discount'

        WHEN TRY_CAST(REPLACE(discount_pct, '%', '') AS FLOAT) <= 10
            THEN 'Low (1-10%)'

        ELSE 'High (11%+)'
    END AS discount_band,

    COUNT(*) AS orders,

    CAST(
        AVG(CAST(quantity AS FLOAT))
        AS DECIMAL(6,2)
    ) AS avg_qty_per_order,

    SUM(net_revenue) AS revenue,

    SUM(profit) AS profit,

    CAST(
        SUM(profit) * 100.0 /
        NULLIF(SUM(net_revenue), 0)
        AS DECIMAL(5,2)
    ) AS margin_pct

FROM dbo.Sales_Analysis

GROUP BY
    CASE
        WHEN TRY_CAST(REPLACE(discount_pct, '%', '') AS FLOAT) = 0
            THEN 'No Discount'

        WHEN TRY_CAST(REPLACE(discount_pct, '%', '') AS FLOAT) <= 10
            THEN 'Low (1-10%)'

        ELSE 'High (11%+)'
    END

ORDER BY revenue DESC;


/* ---------------------------------------------------------
   12. WEEKDAY VS WEEKEND PERFORMANCE
--------------------------------------------------------- */
SELECT
    CASE
        WHEN DATENAME(WEEKDAY, order_date) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(*)                                    AS orders,
    SUM(net_revenue)                            AS revenue,
    CAST(AVG(net_revenue) AS DECIMAL(10,2))     AS avg_order_value
FROM dbo.Sales_Analysis
GROUP BY
    CASE
        WHEN DATENAME(WEEKDAY, order_date) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END;
GO


/* ---------------------------------------------------------
   13. RUNNING TOTAL (CUMULATIVE) REVENUE BY MONTH
--------------------------------------------------------- */
WITH monthly AS (
    SELECT
        FORMAT(order_date, 'yyyy-MM')  AS sales_month,
        SUM(net_revenue)               AS revenue
    FROM dbo.Sales_Analysis
    GROUP BY FORMAT(order_date, 'yyyy-MM')
)
SELECT
    sales_month,
    revenue,
    SUM(revenue) OVER (ORDER BY sales_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM monthly
ORDER BY sales_month;
GO

Select * from dbo.Sales_Analysis;


/* ---------------------------------------------------------
   14. CUSTOMER RFM-STYLE SEGMENTATION (simplified)
   Recency (days since last order), Frequency, Monetary
--------------------------------------------------------- */
WITH cust_stats AS (
    SELECT
        customer_id,
        DATEDIFF(DAY, MAX(order_date), '2025-12-31') AS recency_days,
        COUNT(*)                                      AS frequency,
        SUM(net_revenue)                              AS monetary
    FROM dbo.Sales_Analysis
    GROUP BY customer_id
)
SELECT TOP 20
    customer_id,
    recency_days,
    frequency,
    monetary,
    CASE
        WHEN frequency >= 40 AND monetary >= 3000 THEN 'VIP'
        WHEN frequency >= 20 THEN 'Loyal'
        WHEN recency_days > 180 THEN 'At Risk'
        ELSE 'Regular'
    END AS rfm_segment
FROM cust_stats
ORDER BY monetary DESC;
GO


/* ---------------------------------------------------------
   15. PRODUCT-LEVEL PROFIT MARGIN OUTLIERS (below 25%)
--------------------------------------------------------- */
SELECT
    product,
    category,
    SUM(net_revenue)                                              AS revenue,
    SUM(profit)                                                   AS profit,
    CAST(SUM(profit) * 100.0 / SUM(net_revenue) AS DECIMAL(5,2)) AS margin_pct
FROM dbo.Sales_Analysis
GROUP BY product, category
HAVING SUM(profit) * 100.0 / SUM(net_revenue) < 25
ORDER BY margin_pct ASC;
GO


/* ---------------------------------------------------------
   16. QUARTERLY REVENUE SUMMARY (bonus — common interview ask)
--------------------------------------------------------- */
SELECT
    YEAR(order_date)                    AS sales_year,
    DATEPART(QUARTER, order_date)       AS sales_quarter,
    SUM(net_revenue)                    AS revenue,
    SUM(profit)                         AS profit
FROM dbo.Sales_Analysis
GROUP BY YEAR(order_date), DATEPART(QUARTER, order_date)
ORDER BY sales_year, sales_quarter;
GO


/* ---------------------------------------------------------
   17. FIRST PURCHASE MONTH -> COHORT SIZE (bonus)
--------------------------------------------------------- */
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(FORMAT(order_date, 'yyyy-MM')) AS cohort_month
    FROM dbo.Sales_Analysis
    GROUP BY customer_id
)
SELECT
    cohort_month,
    COUNT(*) AS new_customers
FROM first_purchase
GROUP BY cohort_month
ORDER BY cohort_month;
GO



