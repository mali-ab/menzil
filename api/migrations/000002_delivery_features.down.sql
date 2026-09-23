DROP TABLE IF EXISTS courier_tips;
DROP TABLE IF EXISTS loyalty_events;
DROP TABLE IF EXISTS loyalty_accounts;
DROP TABLE IF EXISTS order_call_sessions;
DROP TABLE IF EXISTS order_chat_messages;
DROP TABLE IF EXISTS order_chat_conversations;
DROP TABLE IF EXISTS delivery_proofs;
DROP TABLE IF EXISTS escrow_transactions;
ALTER TABLE courier_profiles DROP COLUMN IF EXISTS max_active_orders;
