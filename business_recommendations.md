# QuickCart IQ — Business Recommendations

Every number below is pulled directly from the SQL, Python, and Power BI analysis in this repo — not estimated.

## 1. Fix the evening stockout problem

**Finding:** Stockout rate is near 0% overnight and climbs almost linearly to 8.8% by 11 PM, because restocking happens only once per day. This costs an estimated **₹15.6L** in lost revenue, concentrated in a small set of high-demand staples (Milk, Eggs, Curd, Cold Drink, White Bread).

**Recommendation:** Move to a second restock cycle in the afternoon (around 2–3 PM) for the top 10–12 products on the priority replenishment list, rather than restocking every product equally. This targets the specific items causing most of the loss instead of a blanket inventory increase.

## 2. Fix Whitefield's delivery capacity gap

**Finding:** Whitefield's SLA breach rate is **37.1%** — more than double every other zone (12–18%) — and during peak hours (7–9 PM) it hits **66.8%**. The root cause is quantifiable: Whitefield riders each handle **2,399 orders**, versus **1,081** in Koramangala, more than double the load.

**Recommendation:** Increase Whitefield's rider count from 7 to approximately 12. Our regression model (R² = 0.90, meaning rider capacity explains 90% of the variation in SLA breach rate across zones) projects this would cut Whitefield's breach rate from 37% to roughly 18%, in line with the network average.

## 3. Act on the operations-to-retention link before it compounds

**Finding:** Customers in the worst quartile of bad-experience rate (stockouts + late deliveries, relative to how often they order) go **3.82 days** between orders on average, versus **1.73 days** for the best quartile — more than double. 122 customers currently sit in the "At-Risk" segment.

**Recommendation:** Build a simple trigger: any customer who hits 2+ bad experiences (stockout or SLA breach) within a rolling 2-week window gets flagged for a retention action — a small discount, priority stock allocation, or a proactive support outreach — before they silently churn.

## 4. Treat weekday and weekend demand differently

**Finding:** Weekday order volume (70,529) is roughly double weekend volume (35,034), while average order value is nearly identical (₹403 vs ₹400).

**Recommendation:** Weekday staffing and inventory should be built around the higher, more predictable weekday baseline; weekend operations can likely run leaner without hurting revenue, freeing up rider capacity for weekday peak hours instead.

---

*Numbers current as of the analysis in this repo (Feb–May 2026 simulated period). Recalculate if the underlying dataset changes.*
