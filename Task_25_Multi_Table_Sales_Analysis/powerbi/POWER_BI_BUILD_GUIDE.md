# Power BI Build Guide — Task 25

## Recommended model
- `orders`: one row per order
- `order_details`: one row per order line
- `products`: one row per product
- `categories`: one row per category
- `sales_fact_enriched`: optional analysis-ready table

### Relationships
- `orders[order_id]` 1 → * `order_details[order_id]`
- `products[productID]` 1 → * `order_details[product_id]`
- `categories[category_id]` 1 → * `products[categoryID]`

## Core DAX measures
```DAX
Net Sales =
SUMX(
    order_details,
    order_details[unit_price] *
    order_details[quantity] *
    (1 - order_details[discount])
)

Gross Sales =
SUMX(
    order_details,
    order_details[unit_price] *
    order_details[quantity]
)

Discount Value = [Gross Sales] - [Net Sales]

Orders = DISTINCTCOUNT(orders[order_id])

Active Customers = DISTINCTCOUNT(orders[customer_id])

Average Order Value =
DIVIDE([Net Sales], [Orders])

On-Time Delivery % =
DIVIDE(
    CALCULATE(
        DISTINCTCOUNT(orders[order_id]),
        FILTER(
            orders,
            orders[shipped_date] <= orders[required_date]
        )
    ),
    [Orders]
)
```

## Dashboard layout
1. KPI cards: Net Sales, Orders, Active Customers, AOV, On-Time %
2. Line chart: Monthly Net Sales
3. Bar chart: Sales by Category
4. Bar chart: Top 10 Products
5. Bar chart: Top Customers
6. Map / bar chart: Sales by Country
7. Slicers: Year, Category, Country

## Professional design
Use a dark navy header, white canvas, one accent color, compact KPI cards,
consistent currency formatting, and clear chart titles. Avoid chart clutter.
