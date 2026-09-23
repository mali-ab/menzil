CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE roles (
    code TEXT PRIMARY KEY,
    title TEXT NOT NULL
);

INSERT INTO roles (code, title) VALUES
    ('client', 'Müşderi'),
    ('courier', 'Kurýer');

CREATE TABLE transport_types (
    code TEXT PRIMARY KEY,
    title TEXT NOT NULL
);

INSERT INTO transport_types (code, title) VALUES
    ('foot', 'Pyýada'),
    ('bicycle', 'Welosiped'),
    ('scooter', 'Skuter'),
    ('car', 'Awtoulag'),
    ('truck', 'Ýük ulagy');

CREATE TABLE order_statuses (
    code TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    sort_order SMALLINT NOT NULL UNIQUE
);

INSERT INTO order_statuses (code, title, sort_order) VALUES
    ('created', 'Döredildi', 10),
    ('accepted', 'Kurýer kabul etdi', 20),
    ('to_pickup', 'Alyş nokadyna barýar', 30),
    ('delivering', 'Eltip barýar', 40),
    ('delivered', 'Eltirilildi', 50),
    ('cancelled', 'Ýatyryldy', 90);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(32) NOT NULL UNIQUE,
    email CITEXT UNIQUE,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(160) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_code TEXT NOT NULL REFERENCES roles(code),
    PRIMARY KEY (user_id, role_code),
    UNIQUE (user_id)
);

CREATE TABLE client_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE courier_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    transport_type_code TEXT NOT NULL REFERENCES transport_types(code),
    is_available BOOLEAN NOT NULL DEFAULT FALSE,
    rating NUMERIC(3,2) NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    public_number BIGINT GENERATED ALWAYS AS IDENTITY UNIQUE,
    client_id UUID NOT NULL REFERENCES client_profiles(user_id),
    courier_id UUID REFERENCES courier_profiles(user_id),
    required_transport_code TEXT NOT NULL REFERENCES transport_types(code),
    status_code TEXT NOT NULL DEFAULT 'created' REFERENCES order_statuses(code),
    title VARCHAR(180) NOT NULL,
    description TEXT,
    weight_kg NUMERIC(8,2) NOT NULL CHECK (weight_kg > 0),
    length_cm NUMERIC(8,2) NOT NULL CHECK (length_cm > 0),
    width_cm NUMERIC(8,2) NOT NULL CHECK (width_cm > 0),
    height_cm NUMERIC(8,2) NOT NULL CHECK (height_cm > 0),
    pickup_address TEXT NOT NULL,
    pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
    pickup_contact_name VARCHAR(160) NOT NULL,
    pickup_contact_phone VARCHAR(32) NOT NULL,
    delivery_address TEXT NOT NULL,
    delivery_location GEOGRAPHY(POINT, 4326) NOT NULL,
    delivery_contact_name VARCHAR(160) NOT NULL,
    delivery_contact_phone VARCHAR(32) NOT NULL,
    price_amount NUMERIC(12,2) NOT NULL CHECK (price_amount >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'TMT',
    accepted_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (courier_id IS NOT NULL OR status_code IN ('created', 'cancelled'))
);

CREATE TABLE order_status_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status_code TEXT NOT NULL REFERENCES order_statuses(code),
    actor_user_id UUID REFERENCES users(id),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE courier_location_current (
    courier_id UUID PRIMARY KEY REFERENCES courier_profiles(user_id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    accuracy_m NUMERIC(8,2),
    heading_deg NUMERIC(6,2) CHECK (heading_deg IS NULL OR heading_deg BETWEEN 0 AND 360),
    speed_mps NUMERIC(8,2),
    recorded_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE courier_location_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    courier_id UUID NOT NULL REFERENCES courier_profiles(user_id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    accuracy_m NUMERIC(8,2),
    heading_deg NUMERIC(6,2),
    speed_mps NUMERIC(8,2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_available ON orders (required_transport_code, created_at DESC)
    WHERE courier_id IS NULL AND status_code = 'created';
CREATE INDEX idx_orders_client ON orders (client_id, created_at DESC);
CREATE INDEX idx_orders_courier ON orders (courier_id, created_at DESC) WHERE courier_id IS NOT NULL;
CREATE INDEX idx_orders_pickup_location ON orders USING GIST (pickup_location);
CREATE INDEX idx_orders_delivery_location ON orders USING GIST (delivery_location);
CREATE INDEX idx_courier_location_current_geo ON courier_location_current USING GIST (location);
CREATE INDEX idx_courier_location_history_courier_time ON courier_location_history (courier_id, recorded_at DESC);
CREATE INDEX idx_courier_location_history_geo ON courier_location_history USING GIST (location);
CREATE INDEX idx_order_status_history_order ON order_status_history (order_id, created_at);

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER courier_profiles_set_updated_at BEFORE UPDATE ON courier_profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER orders_set_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
