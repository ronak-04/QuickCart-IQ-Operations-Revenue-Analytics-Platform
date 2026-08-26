"""
QuickCart IQ — Python Analysis
Combines the priority replenishment scoring, RFM customer segmentation,
and the rider-capacity decision simulator into one script.

Input files (produced by ../sql/08_export_for_python.sql — run in MySQL,
export each query's results as CSV using the same filenames below):
    product_stockout_summary.csv
    zone_sla_summary.csv
    customer_rfm.csv
    demand_by_hour.csv
    stockout_rate_by_hour.csv

Run this from the same folder as the 5 CSV files above (e.g. upload them
into a Google Colab session, or run locally with them in the same directory).
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ---------------------------------------------------------------
# 1. LOAD DATA
# ---------------------------------------------------------------
product_stockout = pd.read_csv('product_stockout_summary.csv')
zone_sla = pd.read_csv('zone_sla_summary.csv')
customer_rfm = pd.read_csv('customer_rfm.csv')
demand_by_hour = pd.read_csv('demand_by_hour.csv')
stockout_by_hour = pd.read_csv('stockout_rate_by_hour.csv')

print("Loaded:", product_stockout.shape, zone_sla.shape, customer_rfm.shape,
      demand_by_hour.shape, stockout_by_hour.shape)

# ---------------------------------------------------------------
# 2. CHART 1 — Orders vs. Stockout Rate by Hour
#    Shows both problems spike together during the evening peak.
# ---------------------------------------------------------------
fig, ax1 = plt.subplots(figsize=(10, 5))
ax1.bar(demand_by_hour['hour_of_day'], demand_by_hour['total_orders'],
        color='#4C72B0', alpha=0.7, label='Orders')
ax1.set_xlabel('Hour of Day')
ax1.set_ylabel('Total Orders', color='#4C72B0')
ax1.tick_params(axis='y', labelcolor='#4C72B0')

ax2 = ax1.twinx()
ax2.plot(stockout_by_hour['hour_of_day'], stockout_by_hour['stockout_rate_pct'],
          color='#C44E52', linewidth=2.5, marker='o', label='Stockout Rate %')
ax2.set_ylabel('Stockout Rate (%)', color='#C44E52')
ax2.tick_params(axis='y', labelcolor='#C44E52')

plt.title('Orders vs. Stockout Rate by Hour of Day')
fig.tight_layout()
plt.savefig('chart1_demand_vs_stockout.png', dpi=100)
plt.close()

# ---------------------------------------------------------------
# 3. CHART 2 — Priority Replenishment Score
#    Combines lost revenue (60%) and stockout rate (40%) into one
#    ranked score using min-max normalization, so both "how much
#    money is at stake" and "how often it happens" count.
# ---------------------------------------------------------------
def normalize(series):
    return 100 * (series - series.min()) / (series.max() - series.min())

product_stockout['revenue_score'] = normalize(product_stockout['estimated_lost_revenue'])
product_stockout['stockout_score'] = normalize(product_stockout['stockout_rate_pct'])
product_stockout['priority_score'] = (
    0.6 * product_stockout['revenue_score'] + 0.4 * product_stockout['stockout_score']
).round(1)

priority_list = product_stockout.sort_values('priority_score', ascending=False)[
    ['product_name', 'category', 'stockout_rate_pct', 'estimated_lost_revenue', 'priority_score']
]
print("\nTop 10 priority replenishment products:")
print(priority_list.head(10).to_string(index=False))

top12 = priority_list.head(12)
plt.figure(figsize=(9, 6))
plt.barh(top12['product_name'][::-1], top12['priority_score'][::-1], color='#C44E52')
plt.xlabel('Priority Score (0-100)')
plt.title('Top 12 Products — Restocking Priority')
plt.tight_layout()
plt.savefig('chart2_priority_score.png', dpi=100)
plt.close()

# ---------------------------------------------------------------
# 4. CHART 3 — Customer Segments + the Churn Insight
#    Segments customers by order frequency/recency, then proves
#    that customers with a WORSE bad-experience RATE (not raw
#    count — that would be misleading, see README) go longer
#    between orders.
# ---------------------------------------------------------------
def segment(row):
    if row['frequency'] == 0:
        return 'Inactive'
    elif row['recency_days'] >= 10:
        return 'At-Risk'
    elif row['frequency'] >= 60:
        return 'Loyal'
    elif row['frequency'] >= 15:
        return 'Repeat'
    else:
        return 'New'

customer_rfm['segment'] = customer_rfm.apply(segment, axis=1)
print("\nCustomer segments:")
print(customer_rfm['segment'].value_counts())

active = customer_rfm[customer_rfm['frequency'] > 0].copy()
active['bad_rate'] = active['bad_experience_count'] / active['frequency']
active['bad_rate_quartile'] = pd.qcut(active['bad_rate'], 4,
                                        labels=['Best 25%', '2nd', '3rd', 'Worst 25%'])
quartile_summary = active.groupby('bad_rate_quartile', observed=True)['recency_days'].mean().round(2)
print("\nAvg days since last order, by bad-experience-rate quartile:")
print(quartile_summary)

fig, axes = plt.subplots(1, 2, figsize=(13, 5))
seg_order = ['Loyal', 'Repeat', 'New', 'At-Risk', 'Inactive']
seg_counts = customer_rfm['segment'].value_counts().reindex(seg_order)
axes[0].bar(seg_counts.index, seg_counts.values,
            color=['#55A868', '#4C72B0', '#8172B2', '#C44E52', '#999999'])
axes[0].set_title('Customer Segments')
axes[0].set_ylabel('Number of Customers')

axes[1].bar(quartile_summary.index, quartile_summary.values,
            color=['#55A868', '#8DB05C', '#DD8452', '#C44E52'])
axes[1].set_title('Worse Experience -> Longer Since Last Order')
axes[1].set_ylabel('Avg Days Since Last Order')
axes[1].set_xlabel('Bad-Experience Rate Group')
plt.tight_layout()
plt.savefig('chart3_rfm.png', dpi=100)
plt.close()

# ---------------------------------------------------------------
# 5. CHART 4 — The Decision Simulator
#    Fits a linear regression between rider capacity (orders per
#    rider) and SLA breach rate across the 6 zones, then uses it
#    to simulate hypothetical rider counts for Whitefield.
# ---------------------------------------------------------------
slope, intercept = np.polyfit(zone_sla['orders_per_rider'], zone_sla['sla_breach_rate_pct'], 1)
predicted = slope * zone_sla['orders_per_rider'] + intercept
r2 = 1 - ((zone_sla['sla_breach_rate_pct'] - predicted) ** 2).sum() / \
         ((zone_sla['sla_breach_rate_pct'] - zone_sla['sla_breach_rate_pct'].mean()) ** 2).sum()
print(f"\nRegression: SLA breach % = {slope:.5f} * orders_per_rider + {intercept:.2f}  (R² = {r2:.3f})")

whitefield_orders = zone_sla.loc[zone_sla.zone == 'Whitefield', 'total_orders'].values[0]
current_riders = zone_sla.loc[zone_sla.zone == 'Whitefield', 'riders'].values[0]

print(f"\nWhitefield decision simulator (currently {current_riders} riders):")
scenarios = []
for extra in [0, 3, 5, 7, 10]:
    new_riders = current_riders + extra
    ratio = whitefield_orders / new_riders
    breach = max(slope * ratio + intercept, 0)
    scenarios.append((new_riders, ratio, breach))
    print(f"  +{extra} riders (total {new_riders}): orders/rider={ratio:.0f} -> predicted SLA breach = {breach:.1f}%")

fig, axes = plt.subplots(1, 2, figsize=(13, 5))
x_line = np.linspace(900, 2500, 50)
axes[0].plot(x_line, slope * x_line + intercept, '--', color='gray', label='Trend line')
axes[0].scatter(zone_sla['orders_per_rider'], zone_sla['sla_breach_rate_pct'],
                 s=100, color='#4C72B0', zorder=5)
for _, row in zone_sla.iterrows():
    axes[0].annotate(row['zone'], (row['orders_per_rider'], row['sla_breach_rate_pct']),
                      textcoords="offset points", xytext=(5, 5), fontsize=9)
axes[0].set_xlabel('Orders per Rider')
axes[0].set_ylabel('SLA Breach Rate (%)')
axes[0].set_title(f'Rider Capacity vs SLA Breach (R²={r2:.2f})')

riders_list = [s[0] for s in scenarios]
breach_list = [s[2] for s in scenarios]
axes[1].bar([str(r) for r in riders_list], breach_list, color='#C44E52')
axes[1].set_xlabel('Total Riders in Whitefield')
axes[1].set_ylabel('Predicted SLA Breach Rate (%)')
axes[1].set_title('Decision Simulator: Whitefield Rider Scenarios')
other_zones_avg = zone_sla[zone_sla.zone != 'Whitefield']['sla_breach_rate_pct'].mean()
axes[1].axhline(y=other_zones_avg, color='green', linestyle='--', label='Other zones avg')
axes[1].legend()
plt.tight_layout()
plt.savefig('chart4_decision_simulator.png', dpi=100)
plt.close()

print("\nAll 4 charts saved.")
