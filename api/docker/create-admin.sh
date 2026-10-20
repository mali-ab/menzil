#!/bin/sh
set -eu

if [ -z "${ADMIN_PHONE:-}" ]; then printf "Admin phone: "; read -r ADMIN_PHONE; fi
if [ -z "${ADMIN_NAME:-}" ]; then printf "Admin name: "; read -r ADMIN_NAME; fi
if [ -z "${ADMIN_PASSWORD:-}" ]; then
  printf "Admin password: "
  stty -echo
  read -r ADMIN_PASSWORD
  stty echo
  printf "\n"
fi

if [ "${#ADMIN_PASSWORD}" -lt 8 ]; then
  echo "ADMIN_PASSWORD must contain at least 8 characters" >&2
  exit 1
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  --set=admin_phone="$ADMIN_PHONE" \
  --set=admin_password="$ADMIN_PASSWORD" \
  --set=admin_name="$ADMIN_NAME" <<'SQL'
BEGIN;
INSERT INTO users (phone, password_hash, full_name, is_active)
VALUES (:'admin_phone', crypt(:'admin_password', gen_salt('bf', 10)), :'admin_name', TRUE)
ON CONFLICT (phone) DO UPDATE SET
  password_hash = EXCLUDED.password_hash,
  full_name = EXCLUDED.full_name,
  is_active = TRUE,
  updated_at = now();

DELETE FROM user_roles
WHERE user_id = (SELECT id FROM users WHERE phone = :'admin_phone');

INSERT INTO user_roles (user_id, role_code)
SELECT id, 'admin' FROM users WHERE phone = :'admin_phone';
COMMIT;
SQL

echo "Administrator $ADMIN_PHONE is ready."
