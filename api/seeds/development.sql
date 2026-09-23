-- Diňe lokal development üçin demo maglumatlar.
-- Ähli demo hasaplarynyň paroly: password
BEGIN;

INSERT INTO users (id, phone, email, password_hash, full_name) VALUES
    ('10000000-0000-0000-0000-000000000001', '+99360000001', 'aylar@example.test', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Aýlar Döwletowa'),
    ('20000000-0000-0000-0000-000000000001', '+99360000002', 'begench@example.test', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Begenç Amanow'),
    ('30000000-0000-0000-0000-000000000001', '+99360000003', 'meret@example.test', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Meret Geldiýew')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (user_id, role_code) VALUES
    ('10000000-0000-0000-0000-000000000001', 'client'),
    ('20000000-0000-0000-0000-000000000001', 'courier'),
    ('30000000-0000-0000-0000-000000000001', 'courier')
ON CONFLICT DO NOTHING;

INSERT INTO client_profiles (user_id) VALUES
    ('10000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

INSERT INTO courier_profiles (user_id, transport_type_code, is_available, rating) VALUES
    ('20000000-0000-0000-0000-000000000001', 'car', TRUE, 4.90),
    ('30000000-0000-0000-0000-000000000001', 'scooter', TRUE, 4.75)
ON CONFLICT (user_id) DO UPDATE SET
    is_available = EXCLUDED.is_available,
    rating = EXCLUDED.rating;

INSERT INTO orders (
    id, client_id, courier_id, required_transport_code, status_code,
    title, description, weight_kg, length_cm, width_cm, height_cm,
    pickup_address, pickup_location, pickup_contact_name, pickup_contact_phone,
    delivery_address, delivery_location, delivery_contact_name, delivery_contact_phone,
    price_amount, accepted_at
) VALUES
    (
        '40000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001', NULL, 'scooter', 'created',
        'Resminamalar', 'Kiçi bukja, çalt eltip bermek gerek.', 0.40, 32, 24, 4,
        'Berkarar köçesi, Aşgabat', ST_SetSRID(ST_MakePoint(58.3834, 37.9396), 4326)::geography, 'Aýlar', '+99360000001',
        'Arçabil şaýoly, Aşgabat', ST_SetSRID(ST_MakePoint(58.3610, 37.9282), 4326)::geography, 'Alyjy', '+99360000004',
        25.00, NULL
    ),
    (
        '40000000-0000-0000-0000-000000000002',
        '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'car', 'to_pickup',
        'Gül bukedi', 'Seresaplyk bilen eltmeli.', 2.00, 50, 35, 45,
        'Magtymguly şaýoly, Aşgabat', ST_SetSRID(ST_MakePoint(58.3778, 37.9482), 4326)::geography, 'Aýlar', '+99360000001',
        'Gurtly ýaşaýyş jaý toplumy', ST_SetSRID(ST_MakePoint(58.3344, 37.9155), 4326)::geography, 'Alyjy', '+99360000005',
        45.00, now() - interval '5 minutes'
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_status_history (order_id, status_code, actor_user_id)
SELECT source.order_id, source.status_code, source.actor_user_id
FROM (VALUES
    ('40000000-0000-0000-0000-000000000001'::uuid, 'created'::text, '10000000-0000-0000-0000-000000000001'::uuid),
    ('40000000-0000-0000-0000-000000000002'::uuid, 'accepted'::text, '20000000-0000-0000-0000-000000000001'::uuid),
    ('40000000-0000-0000-0000-000000000002'::uuid, 'to_pickup'::text, '20000000-0000-0000-0000-000000000001'::uuid)
) AS source(order_id, status_code, actor_user_id)
WHERE NOT EXISTS (
    SELECT 1 FROM order_status_history history
    WHERE history.order_id = source.order_id
      AND history.status_code = source.status_code
      AND history.actor_user_id = source.actor_user_id
);

INSERT INTO escrow_transactions (id, order_id, client_id, courier_id, amount, currency, status, provider, provider_payment_id, held_at) VALUES
    ('50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000002',
     '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
     45.00, 'TMT', 'held', 'development', 'dev-payment-4002', now())
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO loyalty_accounts (user_id, points_balance) VALUES
    ('10000000-0000-0000-0000-000000000001', 120)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO loyalty_events (id, user_id, order_id, points_delta, reason) VALUES
    ('60000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', NULL, 120, 'Development başlangyç bonusy')
ON CONFLICT (id) DO NOTHING;

COMMIT;
