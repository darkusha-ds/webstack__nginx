#!/usr/bin/env bash
set -euo pipefail

API_URL="https://api.reg.ru/api/regru2/zone/add_txt"

: "${REGRU_USERNAME:?REGRU_USERNAME required}"
: "${REGRU_PASSWORD:?REGRU_PASSWORD required}"
: "${CERTBOT_DOMAIN:?CERTBOT_DOMAIN required}"
: "${CERTBOT_VALIDATION:?CERTBOT_VALIDATION required}"

# Правильно: убираем "*." только если он есть
DNAME="${CERTBOT_DOMAIN}"
if [[ "$DNAME" == \*.* ]]; then
  DNAME="${DNAME:2}"
fi

SUBDOMAIN="_acme-challenge"

echo "[regru-auth] add TXT for dname=${DNAME}, subdomain=${SUBDOMAIN}"

RESP="$(curl -sS -X POST \
  --data-urlencode "username=${REGRU_USERNAME}" \
  --data-urlencode "password=${REGRU_PASSWORD}" \
  --data-urlencode "dname=${DNAME}" \
  --data-urlencode "subdomain=${SUBDOMAIN}" \
  --data-urlencode "text=${CERTBOT_VALIDATION}" \
  --data-urlencode "output_content_type=json" \
  "${API_URL}")"

echo "[regru-auth] response: ${RESP}"

SLEEP="${DNS_PROPAGATION_SECONDS:-120}"
echo "[regru-auth] sleeping ${SLEEP}s for DNS propagation"
sleep "$SLEEP"