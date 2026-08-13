CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.sales (
    sale_id               BIGINT GENERATED ALWAYS AS IDENTITY,
    client_id             INTEGER NOT NULL,
    gender                CHAR(1) NOT NULL,
    purchase_date         DATE NOT NULL,
    purchase_time_seconds INTEGER NOT NULL,
    product_id            INTEGER NOT NULL,
    quantity              SMALLINT NOT NULL,
    price_per_item        NUMERIC(14, 2) NOT NULL,
    discount_per_item     NUMERIC(14, 2) NOT NULL,
    total_price           NUMERIC(16, 2) NOT NULL,
    loaded_at             TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_sales PRIMARY KEY (sale_id)
);

CREATE INDEX IF NOT EXISTS idx_sales_purchase_date
    ON raw.sales (purchase_date);
