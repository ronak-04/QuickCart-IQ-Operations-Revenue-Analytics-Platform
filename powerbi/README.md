# Power BI dashboard

`QuickCart_IQ_Dashboard.pbix` — the full working Power BI file, with all relationships, DAX measures, and 5 pages.

Screenshots of each page are embedded in the main [README](../README.md).

## Pages

1. **Executive Overview** — 6-measure KPI strip, orders-by-hour chart, revenue-by-zone chart, 3 analyst insight callouts
2. **Demand & Sales** — top 8 products by revenue, revenue by category, weekday vs. weekend comparison
3. **Inventory and Lost Revenue** — KPI strip, priority replenishment table (ranked by a normalized 0-100 score combining lost revenue and stockout rate), stockout rate by hour
4. **Delivery Operations** — SLA breach rate by zone, orders per rider by zone, 2 insight callouts on the root cause and the simulated fix
5. **Customer Intelligence** — customer segments, bad-experience-rate vs. recency scatter plot with trend line

## Key DAX measures

```dax
Total Revenue = CALCULATE(SUM(orders[total_amount]), orders[order_status] = "Delivered")
Total Orders = CALCULATE(COUNTROWS(orders), orders[order_status] = "Delivered")
SLA Breach Rate = DIVIDE(SUM(delivery_events[sla_breached]), COUNTROWS(delivery_events))
Stockout Rate = DIVIDE(CALCULATE(COUNTROWS(order_items), order_items[item_status]="Stockout_Removed"), COUNTROWS(order_items))
Estimated Lost Revenue = SUMX(FILTER(order_items, order_items[item_status]="Stockout_Removed"), order_items[quantity]*order_items[unit_price])
```

Full list of measures and calculated columns is documented in the main project notes.
