-- Diňe lokal development üçin demo maglumatlar.
-- Ähli demo hasaplarynyň paroly: password
BEGIN;

INSERT INTO users (id, phone, email, password_hash, full_name) VALUES
    ('10000000-0000-0000-0000-000000000001', '+99360000001', 'aylar@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Aýlar Döwletowa'),
    ('10000000-0000-0000-0000-000000000002', '+99360000010', 'maysa@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Maýsa Orazowa'),
    ('10000000-0000-0000-0000-000000000003', '+99360000011', 'serdar@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Serdar Ataýew'),
    ('10000000-0000-0000-0000-000000000004', '+99360000012', 'selbi@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Selbi Hojamyradowa'),
    ('20000000-0000-0000-0000-000000000001', '+99360000002', 'begench@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Begenç Amanow'),
    ('20000000-0000-0000-0000-000000000002', '+99360000020', 'dowlet@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Döwlet Sähedow'),
    ('20000000-0000-0000-0000-000000000003', '+99360000021', 'jennet@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Jennet Rejebowa'),
    ('20000000-0000-0000-0000-000000000004', '+99360000022', 'myrat@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Myrat Annagulyýew'),
    ('30000000-0000-0000-0000-000000000001', '+99360000003', 'meret@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Meret Geldiýew'),
    ('90000000-0000-0000-0000-000000000001', '+99360000099', 'admin@example.test', '$2a$10$X5wFBtLrL/kHcmrOGGTrGufsBX8CJ0WpQpF3pgeuxBB/H73BK1DW6', 'Menzil Admin')
ON CONFLICT (id) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    full_name = EXCLUDED.full_name,
    is_active = TRUE;

INSERT INTO user_roles (user_id, role_code) VALUES
    ('10000000-0000-0000-0000-000000000001', 'client'),
    ('10000000-0000-0000-0000-000000000002', 'client'),
    ('10000000-0000-0000-0000-000000000003', 'client'),
    ('10000000-0000-0000-0000-000000000004', 'client'),
    ('20000000-0000-0000-0000-000000000001', 'courier'),
    ('20000000-0000-0000-0000-000000000002', 'courier'),
    ('20000000-0000-0000-0000-000000000003', 'courier'),
    ('20000000-0000-0000-0000-000000000004', 'courier'),
    ('30000000-0000-0000-0000-000000000001', 'courier'),
    ('90000000-0000-0000-0000-000000000001', 'admin')
ON CONFLICT DO NOTHING;

INSERT INTO client_profiles (user_id) VALUES
    ('10000000-0000-0000-0000-000000000001'),
    ('10000000-0000-0000-0000-000000000002'),
    ('10000000-0000-0000-0000-000000000003'),
    ('10000000-0000-0000-0000-000000000004')
ON CONFLICT DO NOTHING;

INSERT INTO courier_profiles (user_id, transport_type_code, is_available, rating) VALUES
    ('20000000-0000-0000-0000-000000000001', 'car', TRUE, 4.90),
    ('20000000-0000-0000-0000-000000000002', 'bicycle', TRUE, 4.82),
    ('20000000-0000-0000-0000-000000000003', 'truck', FALSE, 4.68),
    ('20000000-0000-0000-0000-000000000004', 'foot', TRUE, 4.95),
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

-- Admin panelindäki sanaw, süzgüç we diagrammalary barlamak üçin dürli ýagdaýdaky sargytlar.
INSERT INTO orders (
    id, client_id, courier_id, required_transport_code, status_code,
    title, description, weight_kg, length_cm, width_cm, height_cm,
    pickup_address, pickup_location, pickup_contact_name, pickup_contact_phone,
    delivery_address, delivery_location, delivery_contact_name, delivery_contact_phone,
    price_amount, accepted_at, picked_up_at, delivered_at, cancelled_at, created_at
) VALUES
    ('40000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 'scooter', 'delivering',
     'Dermanlar', 'Sowuk ýerde saklamaly.', 0.60, 24, 18, 12,
     'Gorogly köçesi, Aşgabat', ST_SetSRID(ST_MakePoint(58.3921,37.9560),4326)::geography, 'Maýsa', '+99360000010',
     'Bagtyýarlyk şaýoly, Aşgabat', ST_SetSRID(ST_MakePoint(58.4072,37.9258),4326)::geography, 'Mähri', '+99360000031',
     32.00, now()-interval '35 minutes', now()-interval '18 minutes', NULL, NULL, now()-interval '50 minutes'),
    ('40000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002', 'bicycle', 'delivered',
     'Kitaplar', 'Üç sany okuw kitaby.', 1.80, 30, 22, 16,
     'Türkmenbaşy şaýoly, Aşgabat', ST_SetSRID(ST_MakePoint(58.3652,37.9504),4326)::geography, 'Serdar', '+99360000011',
     '10 ýyl Abadançylyk köçesi, Aşgabat', ST_SetSRID(ST_MakePoint(58.3868,37.9328),4326)::geography, 'Gülnar', '+99360000032',
     28.00, now()-interval '2 hours', now()-interval '90 minutes', now()-interval '25 minutes', NULL, now()-interval '3 hours'),
    ('40000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 'truck', 'delivered',
     'Ofis mebeli', 'Iki stol we dört oturgyç.', 85.00, 180, 90, 80,
     'Bitarap Türkmenistan şaýoly, Aşgabat', ST_SetSRID(ST_MakePoint(58.3741,37.9711),4326)::geography, 'Aýlar', '+99360000001',
     'Çandybil şaýoly, Aşgabat', ST_SetSRID(ST_MakePoint(58.3378,37.9062),4326)::geography, 'Batyr', '+99360000033',
     180.00, now()-interval '28 hours', now()-interval '27 hours', now()-interval '25 hours', NULL, now()-interval '30 hours'),
    ('40000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000004', NULL, 'car', 'cancelled',
     'Tort', 'Baýramçylyk torty.', 4.00, 50, 50, 35,
     'Görogly köçesi, Aşgabat', ST_SetSRID(ST_MakePoint(58.3890,37.9448),4326)::geography, 'Selbi', '+99360000012',
     'Parahat 7, Aşgabat', ST_SetSRID(ST_MakePoint(58.3520,37.9380),4326)::geography, 'Oguljan', '+99360000034',
     55.00, NULL, NULL, NULL, now()-interval '70 minutes', now()-interval '2 hours'),
    ('40000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000004', 'foot', 'accepted',
     'Resminama bukjasy', 'Girişde kabul edijä bermeli.', 0.20, 30, 22, 2,
     'Arçabil şaýoly 18, Aşgabat', ST_SetSRID(ST_MakePoint(58.3662,37.9205),4326)::geography, 'Maýsa', '+99360000010',
     'Arçabil şaýoly 24, Aşgabat', ST_SetSRID(ST_MakePoint(58.3728,37.9162),4326)::geography, 'Merdan', '+99360000035',
     18.00, now()-interval '8 minutes', NULL, NULL, NULL, now()-interval '20 minutes'),
    ('40000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', NULL, 'car', 'created',
     'Azyk önümleri', 'Iki guty, döwülýän zat ýok.', 12.00, 60, 40, 35,
     'Gündogar bazary, Aşgabat', ST_SetSRID(ST_MakePoint(58.4210,37.9640),4326)::geography, 'Serdar', '+99360000011',
     'Berzeňňi, Aşgabat', ST_SetSRID(ST_MakePoint(58.3551,37.8870),4326)::geography, 'Aman', '+99360000036',
     70.00, NULL, NULL, NULL, NULL, now()-interval '12 minutes'),
    ('40000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000002', 'bicycle', 'to_pickup',
     'Sport eşikleri', 'Kiçi paket.', 1.20, 35, 25, 15,
     'Olimpiýa şäherçesi, Aşgabat', ST_SetSRID(ST_MakePoint(58.3332,37.9048),4326)::geography, 'Selbi', '+99360000012',
     'Köpetdag şaýoly, Aşgabat', ST_SetSRID(ST_MakePoint(58.3712,37.9371),4326)::geography, 'Aýna', '+99360000037',
     30.00, now()-interval '14 minutes', NULL, NULL, NULL, now()-interval '25 minutes'),
    ('40000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000001', NULL, 'foot', 'created',
     'Açarlar', 'Möhürlenen kiçi bukja.', 0.10, 12, 8, 2,
     'Aşgabat şäher merkezi', ST_SetSRID(ST_MakePoint(58.3817,37.9490),4326)::geography, 'Aýlar', '+99360000001',
     'Kemine köçesi, Aşgabat', ST_SetSRID(ST_MakePoint(58.3972,37.9432),4326)::geography, 'Nury', '+99360000038',
     15.00, NULL, NULL, NULL, NULL, now()-interval '4 minutes')
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_status_history (order_id, status_code, actor_user_id)
SELECT source.order_id, source.status_code, source.actor_user_id
FROM (VALUES
    ('40000000-0000-0000-0000-000000000001'::uuid, 'created'::text, '10000000-0000-0000-0000-000000000001'::uuid),
    ('40000000-0000-0000-0000-000000000002'::uuid, 'accepted'::text, '20000000-0000-0000-0000-000000000001'::uuid),
    ('40000000-0000-0000-0000-000000000002'::uuid, 'to_pickup'::text, '20000000-0000-0000-0000-000000000001'::uuid),
    ('40000000-0000-0000-0000-000000000003'::uuid, 'delivering'::text, '30000000-0000-0000-0000-000000000001'::uuid),
    ('40000000-0000-0000-0000-000000000004'::uuid, 'delivered'::text, '20000000-0000-0000-0000-000000000002'::uuid),
    ('40000000-0000-0000-0000-000000000005'::uuid, 'delivered'::text, '20000000-0000-0000-0000-000000000003'::uuid),
    ('40000000-0000-0000-0000-000000000006'::uuid, 'cancelled'::text, '10000000-0000-0000-0000-000000000004'::uuid),
    ('40000000-0000-0000-0000-000000000007'::uuid, 'accepted'::text, '20000000-0000-0000-0000-000000000004'::uuid),
    ('40000000-0000-0000-0000-000000000008'::uuid, 'created'::text, '10000000-0000-0000-0000-000000000003'::uuid),
    ('40000000-0000-0000-0000-000000000009'::uuid, 'to_pickup'::text, '20000000-0000-0000-0000-000000000002'::uuid),
    ('40000000-0000-0000-0000-000000000010'::uuid, 'created'::text, '10000000-0000-0000-0000-000000000001'::uuid)
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

INSERT INTO delivery_proofs (order_id, photo_url, photo_uploaded_at) VALUES
    ('40000000-0000-0000-0000-000000000002', 'https://example.test/development/proofs/4002.jpg', now() - interval '2 minutes')
ON CONFLICT (order_id) DO UPDATE SET
    photo_url = EXCLUDED.photo_url,
    photo_uploaded_at = EXCLUDED.photo_uploaded_at;

INSERT INTO courier_location_current (courier_id, location, accuracy_m, heading_deg, speed_mps, recorded_at) VALUES
    ('20000000-0000-0000-0000-000000000001', ST_SetSRID(ST_MakePoint(58.3690, 37.9420), 4326)::geography, 8.0, 135, 7.5, now()),
    ('20000000-0000-0000-0000-000000000002', ST_SetSRID(ST_MakePoint(58.3515, 37.9280), 4326)::geography, 5.0, 82, 4.2, now()),
    ('20000000-0000-0000-0000-000000000003', ST_SetSRID(ST_MakePoint(58.4140, 37.9600), 4326)::geography, 12.0, 210, 0.0, now()),
    ('20000000-0000-0000-0000-000000000004', ST_SetSRID(ST_MakePoint(58.3760, 37.9170), 4326)::geography, 4.0, 15, 1.4, now()),
    ('30000000-0000-0000-0000-000000000001', ST_SetSRID(ST_MakePoint(58.3980, 37.9315), 4326)::geography, 6.5, 40, 5.2, now())
ON CONFLICT (courier_id) DO UPDATE SET
    location = EXCLUDED.location,
    accuracy_m = EXCLUDED.accuracy_m,
    heading_deg = EXCLUDED.heading_deg,
    speed_mps = EXCLUDED.speed_mps,
    recorded_at = EXCLUDED.recorded_at;

INSERT INTO courier_location_history (courier_id, location, accuracy_m, heading_deg, speed_mps, recorded_at)
SELECT source.courier_id, source.location, source.accuracy_m, source.heading_deg, source.speed_mps, source.recorded_at
FROM (VALUES
    ('20000000-0000-0000-0000-000000000001'::uuid, ST_SetSRID(ST_MakePoint(58.3710, 37.9440), 4326)::geography, 10.0::numeric, 130.0::numeric, 6.5::numeric, '2026-01-01T10:00:00Z'::timestamptz),
    ('20000000-0000-0000-0000-000000000002'::uuid, ST_SetSRID(ST_MakePoint(58.3480, 37.9295), 4326)::geography, 7.0::numeric, 80.0::numeric, 3.8::numeric, '2026-01-01T10:01:00Z'::timestamptz),
    ('20000000-0000-0000-0000-000000000003'::uuid, ST_SetSRID(ST_MakePoint(58.4120, 37.9580), 4326)::geography, 12.0::numeric, 205.0::numeric, 0.0::numeric, '2026-01-01T10:02:00Z'::timestamptz),
    ('20000000-0000-0000-0000-000000000004'::uuid, ST_SetSRID(ST_MakePoint(58.3740, 37.9190), 4326)::geography, 5.0::numeric, 20.0::numeric, 1.2::numeric, '2026-01-01T10:03:00Z'::timestamptz),
    ('30000000-0000-0000-0000-000000000001'::uuid, ST_SetSRID(ST_MakePoint(58.3950, 37.9340), 4326)::geography, 8.0::numeric, 38.0::numeric, 4.8::numeric, '2026-01-01T10:04:00Z'::timestamptz)
) AS source(courier_id, location, accuracy_m, heading_deg, speed_mps, recorded_at)
WHERE NOT EXISTS (
    SELECT 1 FROM courier_location_history history
    WHERE history.courier_id = source.courier_id
      AND history.recorded_at = source.recorded_at
);

INSERT INTO order_chat_conversations (id, order_id) VALUES
    ('70000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000002')
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO order_chat_messages (id, conversation_id, sender_user_id, body) VALUES
    ('71000000-0000-0000-0000-000000000001', '70000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Salam, gül bukedine seresap boluň.'),
    ('71000000-0000-0000-0000-000000000002', '70000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Salam, alyş nokadyna barýan.')
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_call_sessions (id, order_id, initiator_user_id, provider, provider_room_id, status) VALUES
    ('72000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'development', 'dev-call-4002', 'ended')
ON CONFLICT (id) DO NOTHING;

INSERT INTO loyalty_accounts (user_id, points_balance) VALUES
    ('10000000-0000-0000-0000-000000000001', 120)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO loyalty_events (id, user_id, order_id, points_delta, reason) VALUES
    ('60000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', NULL, 120, 'Development başlangyç bonusy')
ON CONFLICT (id) DO NOTHING;

INSERT INTO courier_tips (id, order_id, client_id, courier_id, amount, currency, payment_status, qr_reference) VALUES
    ('80000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000002',
     '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
     10.00, 'TMT', 'paid', 'development-tip-4002')
ON CONFLICT (id) DO NOTHING;

COMMIT;
