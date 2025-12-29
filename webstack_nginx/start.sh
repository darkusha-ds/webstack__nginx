#!/usr/bin/env bash
set -euo pipefail

: "${CERTBOT_EMAIL:=darkusha.ds@gmail.com}"
: "${DNS_PROPAGATION_SECONDS:=120}"

if [[ -z "${REGRU_USERNAME:-}" || -z "${REGRU_PASSWORD:-}" ]]; then
  echo "❌ REGRU_USERNAME / REGRU_PASSWORD not set"
  exit 1
fi

echo "▶ starting nginx (HTTP bootstrap)"
nginx

echo "▶ issuing wildcard certificates"
/opt/certbot/issue_wildcards.sh

echo "▶ reloading nginx with HTTPS"
nginx -t
nginx -s reload

# авто-renew
(
  while true; do
    sleep 12h
    certbot renew --quiet && nginx -s reload || true
  done
) &

tail -f /var/log/nginx/access.log /var/log/nginx/error.log