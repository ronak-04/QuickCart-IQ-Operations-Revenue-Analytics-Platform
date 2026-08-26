# Data dictionary

The 8 source CSVs referenced by `sql/00_full_setup.sql` are not included in this repo (they total ~35MB and are regenerable). To get them:

- Re-run the generation process described in the main project write-up, or
- Contact the repo owner for the original files

## Tables

| Table | Rows | Description |
|---|---|---|
| `customers` | ~2,545 | Customer profiles |
| `dark_stores` | 14 | Warehouse locations across 6 Bangalore zones |
| `products` | 58 | Product catalog |
| `delivery_partners` | 79 | Delivery riders |
| `orders` | ~106,764 | One row per order |
| `order_items` | ~227,504 | One row per product within an order |
| `delivery_events` | ~105,563 | Delivery timing per order |
| `inventory_snapshots` | ~97,440 | Daily stock level per store per product |

## Known data quality issues (intentional, mirroring real company data)

- Missing phone/email values (customers)
- Inconsistent city spelling/casing
- Duplicate customer sign-ups
- Inconsistent `order_status` text casing
- Duplicate order and delivery event rows
- Order amount outliers
- Negative stock values (simulated sync bug)
- Boolean columns that load as all-zero unless explicitly cast (see `sql/00_full_setup.sql` for the fix)

All of the above are found and corrected in `sql/03_clean_data.sql`.
