-- Esquema inicial do pipeline de pagamentos.
-- Todos os dados do projeto serão sintéticos.

CREATE TABLE IF NOT EXISTS accounts (
    account_id UUID PRIMARY KEY,
    customer_ref VARCHAR(40) NOT NULL UNIQUE,
    account_status VARCHAR(20) NOT NULL
        CHECK (account_status IN ('active', 'blocked', 'closed')),
    country_code CHAR(2) NOT NULL DEFAULT 'AO',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_cards (
    card_id UUID PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES accounts(account_id),
    card_token VARCHAR(64) NOT NULL UNIQUE,
    card_status VARCHAR(20) NOT NULL
        CHECK (card_status IN ('active', 'blocked', 'expired')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_transactions (
    transaction_id UUID PRIMARY KEY,
    card_id UUID NOT NULL REFERENCES payment_cards(card_id),
    merchant_ref VARCHAR(40) NOT NULL,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL DEFAULT 'AOA',
    transaction_status VARCHAR(20) NOT NULL
        CHECK (transaction_status IN ('approved', 'declined', 'pending')),
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para consultas por cartão e tempo.
CREATE INDEX IF NOT EXISTS idx_transactions_card_time
    ON payment_transactions (card_id, occurred_at);

CREATE INDEX IF NOT EXISTS idx_transactions_occurred_at
    ON payment_transactions (occurred_at);

CREATE INDEX IF NOT EXISTS idx_cards_account
    ON payment_cards (account_id);
