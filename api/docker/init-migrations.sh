#!/bin/sh
set -eu

# PostgreSQL-iň standart entrypoint-i ähli *.sql faýllaryny ýerine ýetirýär.
# Bu repo-da down migration-lar hem bar, şonuň üçin diňe up migration-laryny
# aýratyn we san tertibinde ýerine ýetirýäris.
for migration in /migrations/*.up.sql; do
  echo "Migration ýerine ýetirilýär: ${migration}"
  psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    --set ON_ERROR_STOP=1 --file "$migration"
done
