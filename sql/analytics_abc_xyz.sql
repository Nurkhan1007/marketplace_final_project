CREATE MATERIALIZED VIEW analytics.mv_product_abc_xyz AS
WITH month_bounds AS (
    SELECT
        MIN(month_start) AS min_month,

        MAX(month_start) - INTERVAL '1 month'
            AS max_complete_month

    FROM analytics.mv_product_monthly_sales
),

months AS (
    SELECT
        GENERATE_SERIES(
            min_month,
            max_complete_month,
            INTERVAL '1 month'
        )::date AS month_start

    FROM month_bounds
),

product_totals AS (
    SELECT
        product_id,

        SUM(sales_count)::bigint
            AS sales_count,

        SUM(units_sold)::bigint
            AS units_sold,

        SUM(gross_revenue)::numeric(20, 2)
            AS gross_revenue,

        SUM(discount_amount)::numeric(20, 2)
            AS discount_amount,

        SUM(revenue)::numeric(20, 2)
            AS revenue,

        (
            100.0 * SUM(discount_amount)
            / NULLIF(SUM(gross_revenue), 0)
        )::numeric(8, 2)
            AS weighted_discount_pct

    FROM analytics.mv_product_monthly_sales

    GROUP BY product_id
),

product_variability AS (
    SELECT
        pt.product_id,

        COUNT(*)::integer
            AS total_months,

        COUNT(pms.product_id)::integer
            AS active_months,

        AVG(
            COALESCE(pms.units_sold, 0)
        )::numeric(20, 2)
            AS avg_monthly_units,

        STDDEV_POP(
            COALESCE(pms.units_sold, 0)
        )::numeric(20, 2)
            AS stddev_monthly_units

    FROM product_totals AS pt

    CROSS JOIN months AS m

    LEFT JOIN analytics.mv_product_monthly_sales AS pms
        ON pms.product_id = pt.product_id
       AND pms.month_start = m.month_start

    GROUP BY pt.product_id
),

product_metrics AS (
    SELECT
        pt.*,

        pv.total_months,
        pv.active_months,
        pv.avg_monthly_units,
        pv.stddev_monthly_units,

        (
            pv.stddev_monthly_units
            / NULLIF(pv.avg_monthly_units, 0)
        )::numeric(12, 4)
            AS variation_coefficient

    FROM product_totals AS pt

    INNER JOIN product_variability AS pv
        ON pv.product_id = pt.product_id
),

ranked AS (
    SELECT
        pm.*,

        (
            pm.revenue
            / NULLIF(
                SUM(pm.revenue) OVER (),
                0
            )
        )::numeric(12, 8)
            AS revenue_share,

        (
            SUM(pm.revenue) OVER (
                ORDER BY
                    pm.revenue DESC,
                    pm.product_id
                ROWS BETWEEN
                    UNBOUNDED PRECEDING
                    AND CURRENT ROW
            )
            / NULLIF(
                SUM(pm.revenue) OVER (),
                0
            )
        )::numeric(12, 8)
            AS cumulative_revenue_share,

        CUME_DIST() OVER (
            ORDER BY
                pm.variation_coefficient,
                pm.product_id
        )::numeric(12, 8)
            AS stability_percentile

    FROM product_metrics AS pm
),

classified AS (
    SELECT
        ranked.*,

        CASE
            WHEN cumulative_revenue_share <= 0.80
                THEN 'A'
            WHEN cumulative_revenue_share <= 0.95
                THEN 'B'
            ELSE 'C'
        END AS abc_class,

        CASE
            WHEN stability_percentile <= 0.25
                THEN 'X'
            WHEN stability_percentile <= 0.75
                THEN 'Y'
            ELSE 'Z'
        END AS xyz_class

    FROM ranked
)

SELECT
    product_id,
    sales_count,
    units_sold,
    gross_revenue,
    discount_amount,
    revenue,
    weighted_discount_pct,
    total_months,
    active_months,
    avg_monthly_units,
    stddev_monthly_units,
    variation_coefficient,
    revenue_share,
    cumulative_revenue_share,
    stability_percentile,
    abc_class,
    xyz_class,

    CONCAT(abc_class, xyz_class)
        AS abc_xyz_class

FROM classified;


CREATE UNIQUE INDEX ux_mv_product_abc_xyz_product
    ON analytics.mv_product_abc_xyz (product_id);


CREATE INDEX ix_mv_product_abc_xyz_matrix
    ON analytics.mv_product_abc_xyz
       (abc_class, xyz_class);


CREATE INDEX ix_mv_product_abc_xyz_combined
    ON analytics.mv_product_abc_xyz
       (abc_xyz_class);


GRANT SELECT
    ON analytics.mv_product_abc_xyz
    TO metabase_reader;


ANALYZE analytics.mv_product_abc_xyz;
