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

echo "[timeweb-cleanup] remove TXT for dname=${dname}, subdomain=${subdomain}"

token_resp="$(curl -sS -X POST "${ACCESS_URL}" \
  -H "accept: application/json" \
  -H "x-app-key: ${TIMEWEB_API_KEY}" \
  -u "${TIMEWEB_LOGIN}:${TIMEWEB_PASSWORD}")"

token="$(printf '%s' "${token_resp}" | jq -r '.token // empty')"
if [[ -z "${token}" ]]; then
  echo "[timeweb-cleanup] failed to get token: ${token_resp}"
  exit 1
fi

records_resp="$(curl -sS -X GET \
  "${RECORDS_URL_BASE}/${TIMEWEB_LOGIN}/domains/${dname}/user-records?limit=200" \
  -H "accept: application/json" \
  -H "x-app-key: ${TIMEWEB_API_KEY}" \
  -H "Authorization: Bearer ${token}")"

if printf '%s' "${records_resp}" | jq -e '.error? != null' >/dev/null 2>&1; then
  echo "[timeweb-cleanup] records API error: ${records_resp}"
  exit 1
fi

ids="$(printf '%s' "${records_resp}" | jq -r \
  --arg subdomain "${subdomain}" \
  --arg value "${CERTBOT_VALIDATION}" '
  if type == "array" then .
  elif (.data | type) == "array" then .data
  else []
  end
  | map(select(
      .type == "TXT" and
      ((.data.subdomain // "") == $subdomain) and
      ((.data.value // "") == $value)
    ) | .id)
  | .[]?')"

if [[ -z "${ids}" ]]; then
  echo "[timeweb-cleanup] no matching TXT records found"
  exit 0
fi

while IFS= read -r id; do
  [[ -z "${id}" ]] && continue
  delete_resp="$(curl -sS -X DELETE \
    "${RECORDS_URL_BASE}/${TIMEWEB_LOGIN}/domains/${dname}/user-records/${id}/" \
    -H "accept: application/json" \
    -H "x-app-key: ${TIMEWEB_API_KEY}" \
    -H "Authorization: Bearer ${token}" || true)"
  echo "[timeweb-cleanup] deleted id=${id}, response: ${delete_resp}"
done <<< "${ids}"
