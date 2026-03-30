#!/usr/bin/env bash
set -euo pipefail

ACCESS_URL="https://api.timeweb.ru/v1.2/access"
RECORDS_URL_BASE="https://api.timeweb.ru/v1.2/accounts"

: "${TIMEWEB_LOGIN:?TIMEWEB_LOGIN required}"
: "${TIMEWEB_PASSWORD:?TIMEWEB_PASSWORD required}"
: "${TIMEWEB_API_KEY:?TIMEWEB_API_KEY required}"
: "${CERTBOT_DOMAIN:?CERTBOT_DOMAIN required}"
: "${CERTBOT_VALIDATION:?CERTBOT_VALIDATION required}"

dname="${CERTBOT_DOMAIN}"
if [[ "$dname" == \*.* ]]; then
  dname="${dname:2}"
fi

subdomain="_acme-challenge"

echo "[timeweb-auth] add TXT for dname=${dname}, subdomain=${subdomain}"

token_resp="$(curl -sS -X POST "${ACCESS_URL}" \
  -H "accept: application/json" \
  -H "x-app-key: ${TIMEWEB_API_KEY}" \
  -u "${TIMEWEB_LOGIN}:${TIMEWEB_PASSWORD}")"

token="$(printf '%s' "${token_resp}" | jq -r '.token // empty')"
if [[ -z "${token}" ]]; then
  echo "[timeweb-auth] failed to get token: ${token_resp}"
  exit 1
fi

payload="$(jq -cn \
  --arg subdomain "${subdomain}" \
  --arg value "${CERTBOT_VALIDATION}" \
  '{data:{subdomain:$subdomain,value:$value},type:"TXT"}')"

resp="$(curl -sS -X POST \
  "${RECORDS_URL_BASE}/${TIMEWEB_LOGIN}/domains/${dname}/user-records/" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -H "x-app-key: ${TIMEWEB_API_KEY}" \
  -H "Authorization: Bearer ${token}" \
  -d "${payload}")"

if printf '%s' "${resp}" | jq -e '.error? != null' >/dev/null 2>&1; then
  echo "[timeweb-auth] API error: ${resp}"
  exit 1
fi

echo "[timeweb-auth] response: ${resp}"

sleep_seconds="${DNS_PROPAGATION_SECONDS:-120}"
echo "[timeweb-auth] sleeping ${sleep_seconds}s for DNS propagation"
sleep "${sleep_seconds}"
