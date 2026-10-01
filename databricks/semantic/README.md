# Semantic layer — Unity Catalog metric views

Governed business metrics over the migrated `gold.*` marts. Each business
subject is one [Unity Catalog metric view](https://docs.databricks.com/en/metric-views/)
registered as **`${catalog}.semantic.<subject>_metrics`** (`mig_redshift_dev` in
the `dev` bundle target, `mig_redshift` in `prod`). Dimensions and measures are
named exactly like the column aliases of the legacy Redshift BI query
`legacy/redshift/units/<unit>/report.sql`, and their expressions reproduce that
query's aggregation rules (plus the `etl.sql` computed columns it reads), so
grouping a metric view by the report's dimensions returns the legacy report —
verified against `golden/<unit>/report.csv` by `make validate-semantic`.

## Layout

| Path | Purpose |
|---|---|
| `manifest.yaml` | Registry: view name → definition file, legacy unit, and the report shape (dimensions, measures, ORDER BY / LIMIT) used for golden validation |
| `<group>/<subject>.yaml` | Metric view YAML definition (version 1.1) — **the source of truth** |
| `ddl/*.sql` | GENERATED `CREATE SCHEMA` / `CREATE OR REPLACE VIEW ... WITH METRICS LANGUAGE YAML` DDL, one file per view |
| `../resources/semantic_layer.job.yml` | GENERATED bundle job (`semantic_layer`) running the DDL files as SQL tasks |
| `../../tools/semantic_layer.py` | `generate [--check]` DDL + job from the manifest; `deploy` the DDL via a SQL warehouse |
| `../../tools/validate_semantic.py` | Golden validation through the metric views (`make validate-semantic`) |

Sources are written unqualified (`gold.<table>`, `silver.<table>` for joins) and
resolve in the catalog the DDL runs under (`USE CATALOG IDENTIFIER(:catalog)` in
the job, `MIG_CATALOG` for the scripts), so the same definitions deploy to dev
and prod. The `semantic` schema keeps the governed metrics separate from the
physical `gold` tables and the `mart` compatibility views.

## Metric views

| Group | Metric view | Legacy report | Source | Dimensions | Measures |
|---|---|---|---|---|---|
| revenue | `daily_revenue_metrics` | `daily_revenue/report.sql` | `gold.daily_revenue` | order_date, order_month, sales_channel | order_count, revenue |
| revenue | `store_weekly_metrics` | `store_weekly/report.sql` | `gold.store_weekly` ⟕ `silver.stores` | store_id, region, week_start, week_end, week_number | active_weeks, order_count, revenue |
| revenue | `category_mix_metrics` | `category_mix/report.sql` | `gold.category_mix` | category | units_sold, revenue, revenue_share |
| revenue | `product_perf_metrics` | `product_perf/report.sql` | `gold.product_perf` | product_id, category, top_stores | products, units_sold, revenue |
| revenue | `geo_rollup_metrics` | `geo_rollup/report.sql` | `gold.geo_rollup` | grouping_id, grouping_level, region, state | order_count, revenue |
| revenue | `payment_mix_metrics` | `payment_mix/report.sql` | `gold.payment_mix` | method, method_family, method_status | payment_count, amount_total, amount_share |
| revenue | `finance_monthly_metrics` | `finance_export/report.sql` | `gold.finance_monthly` | month, fiscal_year, fiscal_qtr, fiscal_period | order_count, revenue |
| customer | `customer_ltv_metrics` | `customer_ltv/report.sql` | `gold.customer_ltv` | customer_id, region | customers, orders, total_ltv, avg_ltv |
| customer | `churn_flags_metrics` | `churn_flags/report.sql` | `gold.churn_flags` | customer_id, churn_flag, last_order_date | customers, avg_days_since_order |
| customer | `rfm_segments_metrics` | `rfm_segments/report.sql` | `gold.rfm_segments` | customer_id, rfm_segment, r_tile, f_tile, m_tile | customers, total_monetary, avg_frequency |
| customer | `cohort_retention_metrics` | `cohort_retention/report.sql` | `gold.cohort_retention` | cohort_month, month_offset | cohort_size, active_buyers, retention_pct |
| marketing | `attribution_metrics` | `attribution/report.sql` | `gold.attribution` | campaign_id, touch_channel | touches, customers_reached |
| marketing | `promo_lift_metrics` | `promo_lift/report.sql` | `gold.promo_lift` | sales_channel | order_count, median_order_value, p90_order_value |
| marketing | `web_sessions_metrics` | `sessionization/report.sql` | `gold.web_sessions` | customer_id, session_id, session_date | sessions, events, checkout_sessions |
| marketing | `basket_affinity_metrics` | `basket_affinity/report.sql` | `gold.basket_affinity` ⟕ `silver.products` (×2) | product_id_a, product_name_a, product_id_b, product_name_b, pair | pair_orders |
| operations | `shipping_sla_metrics` | `shipping_sla/report.sql` | `gold.shipping_sla` | carrier | shipments, delivered, in_flight, avg_hours_to_deliver, max_hours_to_deliver, on_time_96h, earliest_local_delivery_hour |
| operations | `returns_rate_metrics` | `returns_rate/report.sql` | `gold.returns_rate` | category | sold_qty, returned_qty, return_rate_int, return_pct |
| operations | `inventory_snapshot_metrics` | `inventory_snapshot/report.sql` | `gold.inventory_snapshot` | product_id, snapshot_date | units_sold, on_hand |

Legacy report paths are relative to `legacy/redshift/units/`.

### Preserved legacy semantics

- **Pre-aggregated marts are summed, not re-counted.** e.g. `order_count = SUM(order_count)`,
  `revenue = SUM(revenue)` over the day × channel `gold.daily_revenue`; row-count
  measures (`customers`, `products`, `sessions`) are `COUNT(1)` only where the
  mart has one row per entity, exactly as the report's `COUNT(*)`.
- **Fixed `2025-12-31` anchor.** Churn (`churn_flag`, `days_since_order`), RFM recency and
  the inventory `snapshot_date` come from the gold columns the ETL computed against the
  literal anchor; no definition uses `CURRENT_DATE` or other dynamic dates (enforced by
  `tools/tests/test_semantic_layer.py`).
- **Fiscal calendar.** `fiscal_year` / `fiscal_qtr` are the `gold.finance_monthly` columns
  computed with `f_fiscal_qtr` (`silver.f_fiscal_qtr` on Databricks): the fiscal year starts
  Feb 1 — Feb–Apr = Q1, May–Jul = Q2, Aug–Oct = Q3, Nov–Jan = Q4. `fiscal_period` is the
  `YYYY-Qn` label.
- **Redshift numeric behaviour.** Integer `AVG` truncates (`avg_days_since_order`,
  `avg_frequency`); `avg_ltv` is `AVG(DECIMAL(14,2))` truncated to scale 2; `return_rate_int`
  is integer division and `return_pct` the truncating `DECIMAL(14,4)` division at scale 15,
  recomputed from the summed quantities so they stay correct at any grain;
  `retention_pct = ROUND(100.0 * SUM(active_buyers) / SUM(cohort_size), 2)`.
- **Non-additive mart values are guarded.** Precomputed per-row statistics
  (`median_order_value`, `p90_order_value`, `avg_hours_to_deliver`) return NULL unless the
  query is at their native grain (one channel / carrier) instead of an incorrect re-aggregation.
  Shares (`revenue_share`, `amount_share`) are additive across categories / methods.
- **ROLLUP rows.** `geo_rollup_metrics` keeps the region × state, region-subtotal and
  grand-total rows; always group or filter by `grouping_id` (or `grouping_level`).
- **Double counting as in legacy.** `customers_reached` sums distinct customers per campaign ×
  channel, like the legacy report.

## Querying

Metric views are queried with explicit dimensions and `MEASURE()`; `SELECT *` is not
supported. Monthly revenue by channel:

```sql
USE CATALOG mig_redshift_dev;  -- or mig_redshift

SELECT order_month,
       sales_channel,
       MEASURE(order_count) AS order_count,
       MEASURE(revenue)     AS revenue
FROM   semantic.daily_revenue_metrics
GROUP  BY ALL
ORDER  BY order_month, sales_channel;
```

Re-slice freely — the same governed definitions apply at any grain:

```sql
-- revenue by fiscal quarter label
SELECT fiscal_period, MEASURE(revenue) AS revenue
FROM   semantic.finance_monthly_metrics GROUP BY ALL ORDER BY fiscal_period;

-- overall return rate (recomputed from summed quantities, not an average of rates)
SELECT MEASURE(return_pct) AS return_pct FROM semantic.returns_rate_metrics;

-- region subtotals only (ROLLUP rows)
SELECT region, MEASURE(revenue) AS revenue
FROM   semantic.geo_rollup_metrics WHERE grouping_level = 'region' GROUP BY ALL;
```

The exact query each view is validated with is printed by
`python -c "from tools import semantic_layer as s; print(s.reportQuery(s.loadManifest(), 'daily_revenue_metrics'))"`.

### AI/BI dashboards

Use a metric view as a dashboard dataset (*Data* → *Add data source* → pick
`semantic.<view>`). Dimensions appear as fields and measures as pre-defined
aggregations, so widgets group by any dimension without redefining SQL; or write a
dataset query with `MEASURE()` as above.

### Genie

Add the `semantic.*` metric views to a Genie space as data assets. Genie reads the
view/dimension/measure `comment`s from the YAML and answers questions such as
"monthly revenue by channel in 2025" with the governed measures via `MEASURE()`.

### Permissions

Grant analysts read access to the semantic schema (and the underlying gold/silver
tables, which metric views read with the caller's privileges unless shared otherwise):

```sql
GRANT USE SCHEMA, SELECT ON SCHEMA mig_redshift_dev.semantic TO `analysts`;
```

## Deploying

The `semantic_layer` job (in `databricks/resources/semantic_layer.job.yml`, picked up by
the bundle's `include: resources/*.yml`) runs `ddl/semantic_schema.sql`, then one SQL task
per metric view, against `${var.warehouse_id}` with `catalog: ${var.catalog}`. It is
unscheduled: views only change when definitions change, and the gold tables they read
are refreshed by `nightly_mart_refresh`.

```bash
cd databricks
databricks bundle deploy --target dev --var warehouse_id=<id>
databricks bundle run semantic_layer --target dev --var warehouse_id=<id>
```

Without the bundle, `make semantic-deploy` runs the same DDL through the Statement
Execution API (`DATABRICKS_WAREHOUSE_ID`, `MIG_CATALOG`, default `mig_redshift_dev`).

## Changing a definition

1. Edit `<group>/<subject>.yaml` (and `manifest.yaml` if the report shape changes).
2. `python tools/semantic_layer.py generate` — rewrites `ddl/` and the job resource.
3. `make check` — includes `semantic_layer.py generate --check` and static checks that each
   report's dimensions + measures match the golden columns and keys.
4. `make validate-semantic` (or `make validate-semantic VIEW=daily_revenue_metrics`).

## Validation

`make validate-semantic` (`tools/validate_semantic.py`) deploys the views to `MIG_CATALOG`
(skip with `--skip-deploy`), queries each one with its report dimensions and `MEASURE()` of
its report measures (`GROUP BY ALL` plus the legacy `ORDER BY` / `LIMIT`), and compares the
result with `golden/<unit>/report.csv` using the existing harness comparator
(`validation/compare.py`), the unit's report keys from `.migration/units.yaml`, and the same
tolerances (`validation/tolerances.yaml`). Evidence is written to
`.migration/evidence/semantic/<view>.json`; the target exits non-zero on any FAIL.

Requires `DATABRICKS_WAREHOUSE_ID`, Databricks auth (OIDC; the Makefile mints
`DATABRICKS_OIDC_TOKEN` via `devin-oidc` when available), optional `MIG_CATALOG`, and the
gold marts built (`make validate-all` or the `nightly_mart_refresh` job).
