CREATE MATERIALIZED VIEW analytics.mv_product_monthly_sales AS
SELECT
    DATE_TRUNC(
        'month',
        purchase_date
    )::date AS month_start,

    product_id,

    COUNT(*)::integer AS sales_count,

    COUNT(DISTINCT client_id)::integer
        AS unique_clients,

    SUM(quantity)::bigint
        AS units_sold,

    SUM(quantity * price_per_item)::numeric(20, 2)
        AS gross_revenue,

    SUM(quantity * discount_per_item)::numeric(20, 2)
        AS discount_amount,

    SUM(total_price)::numeric(20, 2)
        AS revenue

FROM raw.sales

GROUP BY
    DATE_TRUNC('month', purchase_date)::date,
    product_id;


CREATE UNIQUE INDEX ux_mv_product_monthly
    ON analytics.mv_product_monthly_sales
       (month_start, product_id);


CREATE INDEX ix_mv_product_monthly_product
    ON analytics.mv_product_monthly_sales
       (product_id, month_start);


GRANT SELECT
    ON analytics.mv_product_monthly_sales
    TO metabase_reader;


ANALYZE analytics.mv_product_monthly_sales;
