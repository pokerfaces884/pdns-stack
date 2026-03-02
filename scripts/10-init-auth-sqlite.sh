
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
DB=./data/pdns-auth/pdns.sqlite3
if [ -f "$DB" ]; then echo "[SKIP] $DB already exists"; exit 0; fi

if [ -f /usr/share/doc/pdns-backend-sqlite3/schema.sqlite3.sql ]; then
  sqlite3 "$DB" < /usr/share/doc/pdns-backend-sqlite3/schema.sqlite3.sql
  echo "[OK] created $DB from local package schema"; exit 0
fi

curl -fsSL https://raw.githubusercontent.com/PowerDNS/pdns/master/modules/gsqlite3backend/schema.sqlite3.sql -o /tmp/schema.sqlite3.sql
sqlite3 "$DB" < /tmp/schema.sqlite3.sql
echo "[OK] created $DB from GitHub schema"
