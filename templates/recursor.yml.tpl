
incoming:
  allow_from:
    - ${RECURSOR_ALLOW_FROM}
  listen:
    - ${RECURSOR_LOCAL_ADDRESS}:${RECURSOR_LOCAL_PORT}

dnssec:
  validation: ${RECURSOR_DNSSEC_MODE}
