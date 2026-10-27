-- Pipeline batch de teste:
-- lê pagamentos do Kafka e publica alertas em JSON.

SET 'execution.runtime-mode' = 'batch';

CREATE TABLE fraud_events (
    transaction_id STRING,
    card_id STRING,
    merchant_ref STRING,
    amount DECIMAL(12, 2),
    currency STRING,
    transaction_status STRING,
    occurred_at TIMESTAMP_LTZ(3)
) WITH (
    'connector' = 'kafka',
    'topic' = 'payments.raw',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'fraud-alert-publisher',
    'scan.startup.mode' = 'earliest-offset',
    'scan.bounded.mode' = 'latest-offset',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
);

CREATE TABLE fraud_alerts (
    transaction_id STRING,
    card_id STRING,
    amount DECIMAL(12, 2),
    occurred_at TIMESTAMP_LTZ(3),
    transactions_in_60_seconds BIGINT,
    alert_type STRING
) WITH (
    'connector' = 'kafka',
    'topic' = 'payments.fraud-alerts',
    'properties.bootstrap.servers' = 'kafka:9092',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
);

INSERT INTO fraud_alerts
SELECT
    a.transaction_id,
    a.card_id,
    a.amount,
    a.occurred_at,
    COUNT(*) AS transactions_in_60_seconds,
    'POTENTIAL_FRAUD' AS alert_type
FROM fraud_events AS a
JOIN fraud_events AS b
    ON a.card_id = b.card_id
    AND a.transaction_status = 'approved'
    AND b.transaction_status = 'approved'
    AND b.occurred_at <= a.occurred_at
    AND TIMESTAMPDIFF(
        SECOND, b.occurred_at, a.occurred_at
    ) BETWEEN 0 AND 60
GROUP BY
    a.transaction_id,
    a.card_id,
    a.amount,
    a.occurred_at
HAVING COUNT(*) >= 3;
