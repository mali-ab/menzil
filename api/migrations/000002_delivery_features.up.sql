-- Ulag görnüşi öňki maglumatlar bazasy üçin hem elýeterli bolsun.
INSERT INTO transport_types (code, title) VALUES ('scooter', 'Skuter')
ON CONFLICT (code) DO NOTHING;

ALTER TABLE courier_profiles
    ADD COLUMN max_active_orders SMALLINT NOT NULL DEFAULT 3
        CHECK (max_active_orders BETWEEN 1 AND 3);

-- Töleg derrew authorize/hold edilýär; kurýere diňe subutnama tassyklanandan soň çykýar.
CREATE TABLE escrow_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
    client_id UUID NOT NULL REFERENCES client_profiles(user_id),
    courier_id UUID REFERENCES courier_profiles(user_id),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL DEFAULT 'TMT',
    status TEXT NOT NULL CHECK (status IN ('pending', 'held', 'released', 'refunded', 'failed')),
    provider TEXT NOT NULL,
    provider_payment_id TEXT UNIQUE,
    held_at TIMESTAMPTZ,
    released_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE delivery_proofs (
    order_id UUID PRIMARY KEY REFERENCES orders(id) ON DELETE CASCADE,
    otp_hash TEXT,
    otp_expires_at TIMESTAMPTZ,
    otp_attempts SMALLINT NOT NULL DEFAULT 0 CHECK (otp_attempts BETWEEN 0 AND 5),
    otp_verified_at TIMESTAMPTZ,
    photo_url TEXT,
    photo_uploaded_at TIMESTAMPTZ,
    verified_by_user_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (otp_hash IS NOT NULL OR photo_url IS NOT NULL)
);

-- Bir sargytda diňe müşderi we bellenen kurýer gatnaşýar; telefon belgileri çatda açylmaýar.
CREATE TABLE order_chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at TIMESTAMPTZ
);

CREATE TABLE order_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES order_chat_conversations(id) ON DELETE CASCADE,
    sender_user_id UUID NOT NULL REFERENCES users(id),
    body TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
    sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at TIMESTAMPTZ
);

-- Signal/Twilio/başga VoIP provider üçin diňe wagtlaýyn, anonim call-room maglumatlary.
CREATE TABLE order_call_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    initiator_user_id UUID NOT NULL REFERENCES users(id),
    provider TEXT NOT NULL,
    provider_room_id TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'active', 'ended', 'failed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ
);

CREATE TABLE loyalty_accounts (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    points_balance INTEGER NOT NULL DEFAULT 0 CHECK (points_balance >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE loyalty_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES loyalty_accounts(user_id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    points_delta INTEGER NOT NULL CHECK (points_delta <> 0),
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE courier_tips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
    client_id UUID NOT NULL REFERENCES client_profiles(user_id),
    courier_id UUID NOT NULL REFERENCES courier_profiles(user_id),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL DEFAULT 'TMT',
    payment_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    qr_reference TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_courier_active ON orders (courier_id, status_code)
    WHERE status_code IN ('accepted', 'to_pickup', 'delivering');
CREATE INDEX idx_chat_messages_conversation ON order_chat_messages (conversation_id, sent_at);
CREATE INDEX idx_loyalty_events_user ON loyalty_events (user_id, created_at DESC);
CREATE INDEX idx_tips_courier ON courier_tips (courier_id, created_at DESC);

CREATE TRIGGER escrow_transactions_set_updated_at
BEFORE UPDATE ON escrow_transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER loyalty_accounts_set_updated_at
BEFORE UPDATE ON loyalty_accounts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
