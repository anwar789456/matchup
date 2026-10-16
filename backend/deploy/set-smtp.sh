#!/usr/bin/env bash
# Stores the Resend API key (used as the SMTP password) in the server's backend/.env (never in
# git) and restarts the utilisateur module. Run it yourself so the key stays with you:
#
#   ssh -t ubuntu@92.222.36.107 sudo bash /opt/matchup/backend/deploy/set-smtp.sh
set -euo pipefail

ENV_FILE=/opt/matchup/backend/.env

read -r -s -p "Resend API key (starts with re_, hidden while you type): " SMTP_PASS
echo
[[ "$SMTP_PASS" == re_* ]] || { echo "That doesn't look like a Resend key (re_...). Nothing changed."; exit 1; }

set_var() {
  local key="$1" value="$2"
  touch "$ENV_FILE"
  sed -i "/^${key}=/d" "$ENV_FILE"
  printf '%s=%s\n' "$key" "$value" >>"$ENV_FILE"
}

# Resend SMTP: user "resend", password = the API key.
set_var SMTP_HOST smtp.resend.com
set_var SMTP_PORT 465
set_var SMTP_USER resend
set_var SMTP_PASS "$SMTP_PASS"
set_var MAIL_FROM "MatchUp <noreply@minolingo.online>"
set_var PUBLIC_URL https://minolingo.online
chown ubuntu:ubuntu "$ENV_FILE"
chmod 600 "$ENV_FILE"

sudo -u ubuntu pm2 restart utilisateur --update-env >/dev/null
echo "Saved. The utilisateur module restarted with the new email settings."
