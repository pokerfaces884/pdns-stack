
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source ./.env; set +a

mkdir -p ./etc/dnsdist ./etc/pdns-auth ./etc/pdns-recursor
mkdir -p ./data/pdns-auth ./data/pdns-admin ./backups

command -v envsubst >/dev/null 2>&1 || { echo "envsubst が必要です: sudo dnf -y install gettext"; exit 1; }

envsubst < ./templates/dnsdist.conf.tpl   > ./etc/dnsdist/dnsdist.conf
envsubst < ./templates/pdns-auth.conf.tpl > ./etc/pdns-auth/pdns.conf
envsubst < ./templates/recursor.yml.tpl   > ./etc/pdns-recursor/recursor.yml

REC_YML=./etc/pdns-recursor/recursor.yml
if [ "${RECURSOR_FORWARD_MODE:-full}" = "forward-external" ]; then
  if [ -n "${RECURSOR_INTERNAL_ZONES:-}" ]; then
    cat >> "$REC_YML" <<EOF

forward_zones:
  - "${RECURSOR_INTERNAL_ZONES}"
EOF
  fi
  fwd=""
  [ -n "${RECURSOR_FORWARDERS_V4:-}" ] && fwd="${RECURSOR_FORWARDERS_V4}"
  if [ -n "${RECURSOR_FORWARDERS_V6:-}" ]; then
    if [ -n "$fwd" ]; then fwd="$fwd;${RECURSOR_FORWARDERS_V6}"; else fwd="${RECURSOR_FORWARDERS_V6}"; fi
  fi
  if [ -n "$fwd" ]; then
    cat >> "$REC_YML" <<EOF

forward_zones_recurse:
  - ".=$fwd"
EOF
  fi
fi

echo "[OK] rendered configs under ./etc/*"
