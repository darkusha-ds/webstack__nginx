#!/usr/bin/env bash
set -euo pipefail

issue() {
  local domain="$1"
  certbot certonly \
    --non-interactive --agree-tos \
    --email "$CERTBOT_EMAIL" \
    --manual --preferred-challenges dns \
    --manual-auth-hook /opt/certbot/regru-auth.sh \
    --manual-cleanup-hook /opt/certbot/regru-cleanup.sh \
    --manual-public-ip-logging-ok \
    -d "$domain" -d "*.$domain"
}

issue dark-angel.ru
issue ticket-flow.ru