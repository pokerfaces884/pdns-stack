
# ===== Authoritative (SQLite + DNSSEC) =====
local-address=0.0.0.0,::

launch=gsqlite3
gsqlite3-database=/var/lib/powerdns/pdns.sqlite3
gsqlite3-dnssec=yes

api=yes
api-key=${PDNS_AUTH_API_KEY}
webserver=yes
webserver-address=${PDNS_AUTH_WEB_BIND}
webserver-port=${PDNS_AUTH_WEB_PORT}
webserver-allow-from=${PDNS_AUTH_WEB_ACL}

recursor=

dnsupdate=no
