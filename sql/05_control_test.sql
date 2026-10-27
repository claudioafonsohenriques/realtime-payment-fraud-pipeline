SET 'execution.runtime-mode' = 'batch';
SET 'sql-client.execution.result-mode' = 'TABLEAU';

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
    'properties.group.id' = 'fraud-control-test',
    'scan.startup.mode' = 'earliest-offset',
    'scan.bounded.mode' = 'latest-offset',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
);

SELECT
    a.transaction_id,
    COUNT(*) AS transactions_in_60_seconds
FROM fraud_events AS a
JOIN fraud_events AS b
    ON a.card_id = b.card_id
    AND a.transaction_status = 'approved'
    AND b.transaction_status = 'approved'
    AND b.occurred_at <= a.occurred_at
    AND TIMESTAMPDIFF(SECOND, b.occurred_at, a.occurred_at)
        BETWEEN 0 AND 60
WHERE a.card_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
GROUP BY
    a.transaction_id,
    a.card_id,
    a.occurred_at
HAVING COUNT(*) >= 3;
