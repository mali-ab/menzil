#!/bin/sh
set -eu

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -c \
  "CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now());"

for migration in /migrations/*.up.sql; do
  version="$(basename "$migration" .up.sql)"
  applied="$(psql "$DATABASE_URL" -Atq -c "SELECT 1 FROM schema_migrations WHERE version = '$version';")"
  if [ "$applied" != "1" ]; then
    echo "Applying migration $version"
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f "$migration" \
      -c "INSERT INTO schema_migrations (version) VALUES ('$version');"
  fi
done
