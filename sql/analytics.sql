CREATE SCHEMA IF NOT EXISTS analytics
    AUTHORIZATION etl_user;


CREATE MATERIALIZED VIEW analytics.mv_daily_sales AS
SELECT
    purchase_date,

    COUNT(*) AS sales_count,
    COUNT(DISTINCT client_id) AS unique_clients,
    COUNT(DISTINCT product_id) AS unique_products,

    SUM(quantity)::bigint AS units_sold,

    SUM(quantity * price_per_item)::numeric(20, 2)
        AS gross_revenue,

    SUM(quantity * discount_per_item)::numeric(20, 2)
        AS discount_amount,

    SUM(total_price)::numeric(20, 2)
        AS revenue,

    AVG(total_price)::numeric(20, 2)
        AS avg_sale_amount,

    (
        100.0 * SUM(quantity * discount_per_item)
        / NULLIF(SUM(quantity * price_per_item), 0)
    )::numeric(8, 2) AS weighted_discount_pct

FROM raw.sales
GROUP BY purchase_date;


CREATE UNIQUE INDEX ux_mv_daily_sales_date
    ON analytics.mv_daily_sales (purchase_date);


GRANT USAGE ON SCHEMA analytics
    TO metabase_reader;

GRANT SELECT ON analytics.mv_daily_sales
    TO metabase_reader;


ALTER DEFAULT PRIVILEGES
    FOR ROLE etl_user
    IN SCHEMA analytics
    GRANT SELECT ON TABLES TO metabase_reader;
