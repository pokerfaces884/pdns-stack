
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source ./.env; set +a

docker compose up -d pdns-auth

docker exec -it pdns-auth pdnsutil zone create "${DOMAIN}" "ns1.${DOMAIN}"
docker exec -it pdns-auth pdnsutil zone create "${REVERSE_ZONE}" "ns1.${DOMAIN}"

docker exec -it pdns-auth pdnsutil rrset add "${DOMAIN}" "${DOMAIN}" NS "ns1.${DOMAIN}"
docker exec -it pdns-auth pdnsutil rrset add "${DOMAIN}" "ns1.${DOMAIN}" A "192.168.1.53"
docker exec -it pdns-auth pdnsutil rrset add "${DOMAIN}" "www.${DOMAIN}" A "192.168.1.10"

docker exec -it pdns-auth pdnsutil zone secure "${DOMAIN}"
docker exec -it pdns-auth pdnsutil zone secure "${REVERSE_ZONE}"
docker exec -it pdns-auth pdnsutil rectify-zone "${DOMAIN}"
docker exec -it pdns-auth pdnsutil rectify-zone "${REVERSE_ZONE}"

echo "[OK] zones created and DNSSEC enabled"
