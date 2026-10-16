#!/usr/bin/env bash
# Installs the Nginx config from the repo, and the https://minolingo.online certificate.
# Run with sudo. Safe to run again (an existing certificate is kept and renewed by certbot).
#
#   sudo bash nginx-install.sh            http only
#   sudo DOMAIN=minolingo.online bash nginx-install.sh   http + https (Let's Encrypt)
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
DOMAIN="${DOMAIN:-}"

mkdir -p /var/www/certbot
cp "$DEPLOY_DIR/matchup_proxy.conf" /etc/nginx/matchup_proxy.conf
cp "$DEPLOY_DIR/matchup_locations.conf" /etc/nginx/matchup_locations.conf
cp "$DEPLOY_DIR/nginx.conf" /etc/nginx/sites-available/matchup
ln -sf /etc/nginx/sites-available/matchup /etc/nginx/sites-enabled/matchup
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

if [[ -n "$DOMAIN" ]]; then
  command -v certbot >/dev/null || apt-get install -y -qq certbot >/dev/null
  if [[ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
    # The team accepted the Let's Encrypt Subscriber Agreement for this domain.
    certbot certonly --webroot -w /var/www/certbot -d "$DOMAIN" -d "www.$DOMAIN" \
      --agree-tos --register-unsafely-without-email --non-interactive
  fi
  cp "$DEPLOY_DIR/nginx-ssl.conf" /etc/nginx/sites-available/matchup-ssl
  ln -sf /etc/nginx/sites-available/matchup-ssl /etc/nginx/sites-enabled/matchup-ssl
  # Reload Nginx after every renewal.
  mkdir -p /etc/letsencrypt/renewal-hooks/deploy
  printf '#!/bin/sh\nsystemctl reload nginx\n' >/etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
  chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
  nginx -t && systemctl reload nginx
  echo "https://$DOMAIN is ready"
fi
