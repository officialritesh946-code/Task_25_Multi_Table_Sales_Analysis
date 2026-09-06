-- ============================================================
-- TASK 25 | MULTI-TABLE SALES ANALYSIS
-- Northwind Traders | PostgreSQL / SQL Server adaptable
-- ============================================================
-- Grain:
--   order_details = one product line per order
--   orders        = one row per order
--   products      = one row per product
--
-- Revenue logic:
--   Gross Sales    = unit_price * quantity
--   Discount Value = gross_sales * discount
--   Net Sales      = gross_sales - discount_value
--
-- IMPORTANT:
--   Do NOT SUM order-level freight after joining to order_details
--   unless freight is first reduced to one row per order.
--   This prevents duplicate counting.

-- 01. DATA QUALITY CHECKS
SELECT COUNT(*) AS order_count, COUNT(DISTINCT order_id) AS distinct_orders
FROM orders;

SELECT COUNT(*) AS order_detail_rows,
       COUNT(DISTINCT order_id) AS orders_in_details,
       COUNT(DISTINCT product_id) AS products_in_details
FROM order_details;

-- 02. CORE MULTI-TABLE SALES VIEW
CREATE OR REPLACE VIEW vw_sales_detail AS
SELECT
    od.order_id,
    o.customer_id,
    o.employee_id,
    o.order_date,
    o.required_date,
    o.shipped_date,
    o.ship_via,
    o.ship_country,
    o.freight,
    od.product_id,
    p.product_name,
    p.category_id,
    c.category_name,
    od.unit_price,
    od.quantity,
    od.discount,
    ROUND((od.unit_price * od.quantity)::numeric, 2) AS gross_sales,
    ROUND((od.unit_price * od.quantity * od.discount)::numeric, 2) AS discount_value,
    ROUND((od.unit_price * od.quantity * (1 - od.discount))::numeric, 2) AS net_sales
FROM order_details od
JOIN orders o ON o.order_id = od.order_id
JOIN products p ON p.product_id = od.product_id
LEFT JOIN categories c ON c.category_id = p.category_id;

-- 03. SALES BY PRODUCT
SELECT
    product_id,
    product_name,
    category_name,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units,
    ROUND(SUM(net_sales)::numeric, 2) AS net_sales,
    DENSE_RANK() OVER (ORDER BY SUM(net_sales) DESC) AS sales_rank
FROM vw_sales_detail
GROUP BY product_id, product_name, category_name
ORDER BY sales_rank;

-- 04. PRODUCT RANK WITHIN CATEGORY
SELECT
    product_id,
    product_name,
    category_name,
    ROUND(SUM(net_sales)::numeric, 2) AS net_sales,
    DENSE_RANK() OVER (
        PARTITION BY category_name
        ORDER BY SUM(net_sales) DESC
    ) AS category_rank
FROM vw_sales_detail
GROUP BY product_id, product_name, category_name
ORDER BY category_name, category_rank;

-- 05. SALES BY CUSTOMER
SELECT
    customer_id,
    ship_country,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(net_sales)::numeric, 2) AS net_sales,
    DENSE_RANK() OVER (ORDER BY SUM(net_sales) DESC) AS customer_rank
FROM vw_sales_detail
GROUP BY customer_id, ship_country
ORDER BY customer_rank;

-- 06. MONTHLY SALES + RUNNING TOTAL
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        COUNT(DISTINCT order_id) AS orders,
        ROUND(SUM(net_sales)::numeric, 2) AS net_sales
    FROM vw_sales_detail
    GROUP BY 1
)
SELECT
    month,
    orders,
    net_sales,
    ROUND(
        SUM(net_sales) OVER (
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )::numeric, 2
    ) AS running_net_sales,
    ROUND(
        100.0 * (
            net_sales / NULLIF(LAG(net_sales) OVER (ORDER BY month), 0) - 1
        )::numeric, 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- 07. CATEGORY PERFORMANCE
SELECT
    category_name,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units,
    ROUND(SUM(net_sales)::numeric, 2) AS net_sales,
    ROUND(
        100.0 * SUM(net_sales) / SUM(SUM(net_sales)) OVER ()::numeric, 2
    ) AS sales_share_pct,
    DENSE_RANK() OVER (ORDER BY SUM(net_sales) DESC) AS category_rank
FROM vw_sales_detail
GROUP BY category_name
ORDER BY category_rank;

-- 08. COUNTRY PERFORMANCE
SELECT
    ship_country,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(net_sales)::numeric, 2) AS net_sales,
    DENSE_RANK() OVER (ORDER BY SUM(net_sales) DESC) AS country_rank
FROM vw_sales_detail
GROUP BY ship_country
ORDER BY country_rank;

-- 09. ORDER-LEVEL KPI TABLE (prevents freight duplication)
WITH order_level AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.ship_country,
        o.freight,
        o.required_date,
        o.shipped_date,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS net_sales
    FROM orders o
    JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date, o.ship_country,
             o.freight, o.required_date, o.shipped_date
)
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(net_sales)::numeric, 2) AS total_net_sales,
    ROUND(AVG(net_sales)::numeric, 2) AS avg_order_value,
    ROUND(AVG((shipped_date - order_date))::numeric, 2) AS avg_delivery_days,
    ROUND(100.0 * AVG(
        CASE WHEN shipped_date <= required_date THEN 1.0 ELSE 0.0 END
    )::numeric, 2) AS on_time_rate_pct,
    ROUND(SUM(freight)::numeric, 2) AS total_freight
FROM order_level;

-- 10. TOP 10 CUSTOMERS
WITH customer_sales AS (
    SELECT
        customer_id,
        ROUND(SUM(net_sales)::numeric, 2) AS net_sales
    FROM vw_sales_detail
    GROUP BY customer_id
)
SELECT *,
       DENSE_RANK() OVER (ORDER BY net_sales DESC) AS customer_rank
FROM customer_sales
ORDER BY customer_rank
LIMIT 10;

-- 11. TOP 10 PRODUCTS
WITH product_sales AS (
    SELECT
        product_id,
        product_name,
        ROUND(SUM(net_sales)::numeric, 2) AS net_sales
    FROM vw_sales_detail
    GROUP BY product_id, product_name
)
SELECT *,
       DENSE_RANK() OVER (ORDER BY net_sales DESC) AS product_rank
FROM product_sales
ORDER BY product_rank
LIMIT 10;

-- 12. ANSWER TO "HOW DO YOU AVOID DOUBLE COUNTING?"
-- Keep order-level measures at order grain.
-- If joining orders to order_details, aggregate details back to order_id
-- before summing freight or other order-level fields.
