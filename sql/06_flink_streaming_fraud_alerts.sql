-- Deteção contínua de padrões suspeitos com Flink SQL.
-- Cada alerta representa um cartão com pelo menos três
-- pagamentos aprovados numa janela deslizante de 60 segundos.
-- As janelas avançam a cada 10 segundos.

SET 'execution.runtime-mode' = 'streaming';
SET 'execution.checkpointing.interval' = '10 s';

CREATE TABLE fraud_events_stream (
    transaction_id STRING,
    card_id STRING,
    merchant_ref STRING,
    amount DECIMAL(12, 2),
    currency STRING,
    transaction_status STRING,
    occurred_at TIMESTAMP_LTZ(3),
    WATERMARK FOR occurred_at AS
        occurred_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'payments.raw',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'fraud-alert-stream-v2',
    'scan.startup.mode' = 'latest-offset',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
);

CREATE TABLE fraud_alerts_stream (
    card_id STRING,
    window_start TIMESTAMP_LTZ(3),
    window_end TIMESTAMP_LTZ(3),
    transactions_in_60_seconds BIGINT,
    alert_type STRING
) WITH (
    'connector' = 'kafka',
    'topic' = 'payments.fraud-alerts-stream',
    'properties.bootstrap.servers' = 'kafka:9092',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
);

INSERT INTO fraud_alerts_stream
SELECT
    card_id,
    window_start,
    window_end,
    COUNT(*) AS transactions_in_60_seconds,
    'POTENTIAL_FRAUD' AS alert_type
FROM TABLE(
    HOP(
        TABLE fraud_events_stream,
        DESCRIPTOR(occurred_at),
        INTERVAL '10' SECOND,
        INTERVAL '60' SECOND
    )
)
WHERE transaction_status = 'approved'
GROUP BY
    card_id,
    window_start,
    window_end
HAVING COUNT(*) >= 3;
