
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source ./.env; set +a

# ensure auth is up
docker compose up -d pdns-auth

# create zones
set +e
docker exec -it pdns-auth pdnsutil zone create "${DOMAIN}" "ns1.${DOMAIN}"
docker exec -it pdns-auth pdnsutil zone create "${REVERSE_ZONE}" "ns1.${DOMAIN}"
set -e

# minimal records (edit as needed)
docker exec -it pdns-auth pdnsutil rrset add "${DOMAIN}" "${DOMAIN}" NS "ns1.${DOMAIN}" || true
docker exec -it pdns-auth pdnsutil rrset add "${DOMAIN}" "ns1.${DOMAIN}" A "192.168.1.53" || true
docker exec -it pdns-auth pdnsutil rrset add "${DOMAIN}" "www.${DOMAIN}" A "192.168.1.10" || true

# DNSSEC on
docker exec -it pdns-auth pdnsutil zone secure "${DOMAIN}"
docker exec -it pdns-auth pdnsutil zone secure "${REVERSE_ZONE}"

docker exec -it pdns-auth pdnsutil rectify-zone "${DOMAIN}"
docker exec -it pdns-auth pdnsutil rectify-zone "${REVERSE_ZONE}"

echo "[OK] zones created and DNSSEC enabled"
