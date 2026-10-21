-- Dados totalmente sintéticos e reproduzíveis.
-- Cartão 1: três transações em 40 segundos.
-- Cartão 2: transações espaçadas, como cenário de controlo.

INSERT INTO accounts (
    account_id, customer_ref, account_status, country_code
)
VALUES
(
    '11111111-1111-4111-8111-111111111111',
    'CUSTOMER-001', 'active', 'AO'
),
(
    '22222222-2222-4222-8222-222222222222',
    'CUSTOMER-002', 'active', 'AO'
)
ON CONFLICT DO NOTHING;

INSERT INTO payment_cards (
    card_id, account_id, card_token, card_status
)
VALUES
(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '11111111-1111-4111-8111-111111111111',
    'SYNTHETIC-CARD-001', 'active'
),
(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    '22222222-2222-4222-8222-222222222222',
    'SYNTHETIC-CARD-002', 'active'
)
ON CONFLICT DO NOTHING;

INSERT INTO payment_transactions (
    transaction_id, card_id, merchant_ref,
    amount, currency, transaction_status, occurred_at
)
VALUES
-- Cenário de teste: três transações em 40 segundos.
(
    '10000000-0000-4000-8000-000000000001',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'MERCHANT-001', 1500.00, 'AOA', 'approved',
    '2026-10-20 12:00:00+00'
),
(
    '10000000-0000-4000-8000-000000000002',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'MERCHANT-002', 2500.00, 'AOA', 'approved',
    '2026-10-20 12:00:20+00'
),
(
    '10000000-0000-4000-8000-000000000003',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    'MERCHANT-003', 3200.00, 'AOA', 'approved',
    '2026-10-20 12:00:40+00'
),

-- Cenário de controlo: intervalo superior a 60 segundos.
(
    '20000000-0000-4000-8000-000000000001',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'MERCHANT-004', 800.00, 'AOA', 'approved',
    '2026-10-20 12:00:00+00'
),
(
    '20000000-0000-4000-8000-000000000002',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'MERCHANT-005', 900.00, 'AOA', 'approved',
    '2026-10-20 12:01:30+00'
),
(
    '20000000-0000-4000-8000-000000000003',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'MERCHANT-006', 1100.00, 'AOA', 'approved',
    '2026-10-20 12:03:00+00'
)
ON CONFLICT DO NOTHING;
