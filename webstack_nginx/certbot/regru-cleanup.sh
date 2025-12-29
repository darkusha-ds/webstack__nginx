#!/usr/bin/env bash
set -euo pipefail

API_URL="https://api.reg.ru/api/regru2/zone/remove_record"

: "${REGRU_USERNAME:?REGRU_USERNAME required}"
: "${REGRU_PASSWORD:?REGRU_PASSWORD required}"
: "${CERTBOT_DOMAIN:?CERTBOT_DOMAIN required}"
: "${CERTBOT_VALIDATION:?CERTBOT_VALIDATION required}"

DNAME="${CERTBOT_DOMAIN}"
if [[ "$DNAME" == \*.* ]]; then
  DNAME="${DNAME:2}"
fi

SUBDOMAIN="_acme-challenge"

echo "[regru-cleanup] remove TXT for dname=${DNAME}, subdomain=${SUBDOMAIN}"

RESP="$(curl -sS -X POST \
  --data-urlencode "username=${REGRU_USERNAME}" \
  --data-urlencode "password=${REGRU_PASSWORD}" \
  --data-urlencode "dname=${DNAME}" \
  --data-urlencode "subdomain=${SUBDOMAIN}" \
  --data-urlencode "record_type=TXT" \
  --data-urlencode "content=${CERTBOT_VALIDATION}" \
  --data-urlencode "output_content_type=json" \
  "${API_URL}" || true)"

echo "[regru-cleanup] response: ${RESP}"