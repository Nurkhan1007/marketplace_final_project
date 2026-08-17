CREATE MATERIALIZED VIEW analytics.mv_customer_rfm AS
WITH parameters AS (
    SELECT MAX(purchase_date) AS analysis_date
    FROM raw.sales
),

customer_metrics AS (
    SELECT
        s.client_id,

        CASE
            WHEN MIN(s.gender) = MAX(s.gender)
                THEN MIN(s.gender)::text
            ELSE 'Mixed'
        END AS gender,

        p.analysis_date,
        MIN(s.purchase_date) AS first_purchase_date,
        MAX(s.purchase_date) AS last_purchase_date,

        p.analysis_date - MAX(s.purchase_date)
            AS recency_days,

        COUNT(*)::integer AS frequency,
        COUNT(DISTINCT s.purchase_date)::integer
            AS active_days,

        SUM(s.quantity)::bigint AS units_purchased,
        SUM(s.total_price)::numeric(20, 2)
            AS monetary,

        AVG(s.total_price)::numeric(20, 2)
            AS avg_sale_amount

    FROM raw.sales AS s
    CROSS JOIN parameters AS p

    GROUP BY
        s.client_id,
        p.analysis_date
),

ranked AS (
    SELECT
        cm.*,

        CUME_DIST() OVER (
            ORDER BY recency_days
        ) AS recency_distribution,

        CUME_DIST() OVER (
            ORDER BY frequency
        ) AS frequency_distribution,

        CUME_DIST() OVER (
            ORDER BY monetary
        ) AS monetary_distribution

    FROM customer_metrics AS cm
),

scored AS (
    SELECT
        ranked.*,

        (
            6 - CEIL(recency_distribution * 5)
        )::smallint AS r_score,

        CEIL(
            frequency_distribution * 5
        )::smallint AS f_score,

        CEIL(
            monetary_distribution * 5
        )::smallint AS m_score

    FROM ranked
)

SELECT
    client_id,
    gender,
    analysis_date,
    first_purchase_date,
    last_purchase_date,
    recency_days,
    frequency,
    active_days,
    units_purchased,
    monetary,
    avg_sale_amount,
    r_score,
    f_score,
    m_score,

    CONCAT(r_score, f_score, m_score)
        AS rfm_code,

    CASE
        WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
            THEN 'Champions'

        WHEN r_score <= 2
             AND f_score = 5
             AND m_score >= 4
            THEN 'Cannot lose'

        WHEN r_score <= 2
             AND f_score >= 3
            THEN 'At risk'

        WHEN r_score >= 3
             AND f_score >= 4
            THEN 'Loyal customers'

        WHEN r_score >= 4
             AND f_score BETWEEN 2 AND 3
            THEN 'Potential loyalists'

        WHEN r_score = 5
             AND f_score = 1
            THEN 'New customers'

        WHEN r_score = 4
             AND f_score = 1
            THEN 'Promising'

        WHEN r_score = 3
             AND f_score >= 3
            THEN 'Need attention'

        WHEN r_score = 3
             AND f_score <= 2
            THEN 'About to sleep'

        ELSE 'Hibernating'
    END AS rfm_segment

FROM scored;


CREATE UNIQUE INDEX ux_mv_customer_rfm_client
    ON analytics.mv_customer_rfm (client_id);


CREATE INDEX ix_mv_customer_rfm_segment
    ON analytics.mv_customer_rfm (rfm_segment);


CREATE INDEX ix_mv_customer_rfm_scores
    ON analytics.mv_customer_rfm
       (r_score, f_score, m_score);


GRANT SELECT ON analytics.mv_customer_rfm
    TO metabase_reader;


ANALYZE analytics.mv_customer_rfm;
