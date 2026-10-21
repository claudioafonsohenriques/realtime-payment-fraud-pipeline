-- Deteção de três ou mais transações aprovadas
-- do mesmo cartão numa janela móvel de 60 segundos.

WITH approved_transactions AS (
    SELECT
        transaction_id,
        card_id,
        merchant_ref,
        amount,
        currency,
        occurred_at
    FROM payment_transactions
    WHERE transaction_status = 'approved'
),
transaction_counts AS (
    SELECT
        transaction_id,
        card_id,
        merchant_ref,
        amount,
        currency,
        occurred_at,
        COUNT(*) OVER (
            PARTITION BY card_id
            ORDER BY occurred_at
            RANGE BETWEEN INTERVAL '60 seconds' PRECEDING
                      AND CURRENT ROW
        ) AS transactions_in_60_seconds
    FROM approved_transactions
)
SELECT
    transaction_id,
    card_id,
    merchant_ref,
    amount,
    currency,
    occurred_at,
    transactions_in_60_seconds,
    'POTENTIAL_FRAUD' AS alert_type
FROM transaction_counts
WHERE transactions_in_60_seconds >= 3
ORDER BY occurred_at, card_id;
