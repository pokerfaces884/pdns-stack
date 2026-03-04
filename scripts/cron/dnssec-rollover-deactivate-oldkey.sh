
#!/usr/bin/env bash
# DNSSEC ローテーション（第2段階）: 古い鍵を無効化（猶予期間後）
# 既定: "active" の鍵のうち最も古いものを無効化します。
# 実行前に必ず list-zone-keys の出力を確認してください。
set -euo pipefail

DOMAIN="${DOMAIN:-}"
CONTAINER="${PDNS_AUTH_CONTAINER:-pdns-auth}"
DRYRUN="${DRYRUN:-0}"

if [ -z "$DOMAIN" ]; then
  echo "DOMAIN が未指定です。例: DOMAIN=example.com $0" >&2
  exit 2
fi

echo "[INFO] keys for $DOMAIN"
keys=$(docker exec "$CONTAINER" pdnsutil list-zone-keys "$DOMAIN" 2>/dev/null || true)
if [ -z "$keys" ]; then
  echo "[ERROR] list-zone-keys failed or returned empty" >&2
  exit 1
fi

echo "$keys"

# list-zone-keys の出力形式はバージョンで差異があるため、
# 先頭列が Key ID で、行内に 'Active' を含むものを候補とする
# その中から最小の ID を「古い鍵」として選択
old_id=$(echo "$keys" | awk 'NR>1 && $1 ~ /^[0-9]+$/ && tolower($0) ~ /active/ {print $1}' | sort -n | head -n 1)

if [ -z "$old_id" ]; then
  echo "[ERROR] could not determine an active key id to deactivate" >&2
  exit 1
fi

echo "[INFO] candidate old key id: $old_id"
if [ "$DRYRUN" = "1" ]; then
  echo "[DRYRUN] would run: pdnsutil deactivate-zone-key $DOMAIN $old_id"
  exit 0
fi

docker exec "$CONTAINER" pdnsutil deactivate-zone-key "$DOMAIN" "$old_id"

echo "[INFO] updated keys:"
docker exec "$CONTAINER" pdnsutil list-zone-keys "$DOMAIN" || true

echo "[INFO] DS check (update registrar if required):"
docker exec "$CONTAINER" pdnsutil export-zone-ds "$DOMAIN" || true
