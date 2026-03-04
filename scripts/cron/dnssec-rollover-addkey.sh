
#!/usr/bin/env bash
# DNSSEC ローテーション（第1段階）: 新しい CSK を追加して有効化
# 実行例: DOMAIN=example.com KEY_ALGO=ecdsa256 ./scripts/cron/dnssec-rollover-addkey.sh
set -euo pipefail

DOMAIN="${DOMAIN:-}"
KEY_ALGO="${KEY_ALGO:-${DNSSEC_KEY_ALGO:-ecdsa256}}"
CONTAINER="${PDNS_AUTH_CONTAINER:-pdns-auth}"

if [ -z "$DOMAIN" ]; then
  echo "DOMAIN が未指定です。例: DOMAIN=example.com $0" >&2
  exit 2
fi

echo "[INFO] add and activate new key for $DOMAIN (algo=$KEY_ALGO)"
docker exec "$CONTAINER" pdnsutil add-zone-key "$DOMAIN" active "$KEY_ALGO"

echo "[INFO] current keys:"
docker exec "$CONTAINER" pdnsutil list-zone-keys "$DOMAIN" || true

echo "[INFO] DS (registrar update may be needed if you change KSK/CSK set):"
docker exec "$CONTAINER" pdnsutil export-zone-ds "$DOMAIN" || true
