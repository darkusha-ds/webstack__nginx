#!/usr/bin/env bash
set -euo pipefail

API="https://api.reg.ru/api/regru2"

DOMAIN="${CERTBOT_DOMAIN#*.}"
ZONE="$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$NF}')"

curl -s "$API" \
  -d "username=$REGRU_USERNAME" \
  -d "password=$REGRU_PASSWORD" \
  -d "method=zone.add_txt" \
  -d "domain_name=$ZONE" \
  -d "subdomain=_acme-challenge" \
  -d "text=$CERTBOT_VALIDATION" \
  -d "output_format=json"