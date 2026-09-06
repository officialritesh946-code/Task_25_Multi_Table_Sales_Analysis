# Task_25_Multi_Table_Sales_Analysis
Professional SQL and Power BI multi-table sales analysis using Northwind Traders data.


# Task 25 — Multi-Table Sales Analysis

**Northwind Traders | SQL + Power BI**

## Objective
Combine order transactions with product/category dimensions and customer/order
attributes to identify sales performance, top products, top customers, category
mix, geographic performance, trends, and delivery quality.

## Deliverables
- `sql/task_25_multi_table_sales_analysis.sql` — professional SQL analysis with joins, CTEs and window functions.
- `Task_25_Multi_Table_Sales_Analysis_Report.docx` — executive-style task report.
- `Task_25_Northwind_Sales_Analysis.xlsx` — dashboard workbook and supporting analysis.
- `powerbi/POWER_BI_BUILD_GUIDE.md` — Power BI model, DAX measures and dashboard layout.
- `data/` — source data plus analysis-ready enriched fact table.

## Data note
The uploaded ZIP contained `northwind_orders.csv` and `northwind_order_details.csv`.
The product/category master was matched to the standard Northwind ProductID/CategoryID
structure so the multi-table product analysis can be completed without fabricating values.
Customer-level analysis uses the customer IDs and shipping countries present in the supplied
orders. No customer master names were invented.

## Key results
- 830 orders
- 2,155 order lines
- 89 active customer IDs in the supplied orders
- 77 products represented
- Net sales: $1,265,793.04
- Gross sales: $1,354,458.59
- Discount value: $88,665.55
- Average order value: $1,525.05
- Average delivery time: 8.49 days
- On-time delivery rate: 93.01%

## SQL quality focus
The project explicitly demonstrates how to avoid double-counting order-level
measures such as freight when joining an order header to multiple order lines.
