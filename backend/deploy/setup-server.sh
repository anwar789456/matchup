#!/usr/bin/env bash
# One-time setup of the MatchUp server (Ubuntu, run with sudo). Safe to run again.
#
#   sudo DB_PASSWORD='...' bash setup-server.sh
#
# Installs PostgreSQL (open to the team's laptops on port 5432), Node 22, pm2 and Nginx, clones
# the repo to /opt/matchup, builds the 6 modules and starts them, the GitHub webhook and a
# 1-minute git poll as a fallback.
set -euo pipefail

: "${DB_PASSWORD:?Set DB_PASSWORD}"
REPO_URL="${REPO_URL:-https://github.com/anwar789456/matchup.git}"
REPO_DIR=/opt/matchup
APP_USER="${APP_USER:-ubuntu}"
export DEBIAN_FRONTEND=noninteractive

echo "== packages"
apt-get update -qq
apt-get install -y -qq curl git nginx postgresql postgresql-contrib ca-certificates >/dev/null
if ! command -v node >/dev/null || [[ "$(node -v)" != v22* ]]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null
  apt-get install -y -qq nodejs >/dev/null
fi
command -v pm2 >/dev/null || npm install -g pm2 >/dev/null

echo "== postgres"
PG_CONF_DIR=$(ls -d /etc/postgresql/*/main | sort -V | tail -1)
sed -i "s/^#\?listen_addresses.*/listen_addresses = '*'/" "$PG_CONF_DIR/postgresql.conf"
grep -q 'matchup-team' "$PG_CONF_DIR/pg_hba.conf" || cat >>"$PG_CONF_DIR/pg_hba.conf" <<'EOF'
# matchup-team: the team's laptops connect from anywhere with the password
host    all    all    0.0.0.0/0    scram-sha-256
host    all    all    ::/0         scram-sha-256
EOF
systemctl restart postgresql
sudo -u postgres psql -v ON_ERROR_STOP=1 -q <<EOF
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'matchup') THEN
    CREATE ROLE matchup LOGIN PASSWORD '$DB_PASSWORD';
  ELSE
    ALTER ROLE matchup PASSWORD '$DB_PASSWORD';
  END IF;
END \$\$;
EOF
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='matchup'" | grep -q 1 ||
  sudo -u postgres createdb -O matchup matchup

echo "== code"
mkdir -p /var/log/matchup "$REPO_DIR"
chown -R "$APP_USER:$APP_USER" /var/log/matchup "$REPO_DIR"
if [[ ! -d "$REPO_DIR/.git" ]]; then
  sudo -u "$APP_USER" git clone --quiet "$REPO_URL" "$REPO_DIR"
fi
cat >"$REPO_DIR/backend/.env" <<EOF
DB_HOST=localhost
DB_PORT=5432
DB_USER=matchup
DB_PASSWORD=$DB_PASSWORD
DB_NAME=matchup
DB_SYNC=all
EOF
chown "$APP_USER:$APP_USER" "$REPO_DIR/backend/.env"
chmod +x "$REPO_DIR/backend/deploy/"*.sh

echo "== build and start"
sudo -u "$APP_USER" bash -c "cd $REPO_DIR/backend && npm ci --no-audit --no-fund && npm run build" >/var/log/matchup/first-build.log 2>&1 \
  || { echo "build failed, see /var/log/matchup/first-build.log"; exit 1; }
sudo -u "$APP_USER" bash -c "cd $REPO_DIR/backend && pm2 startOrReload deploy/ecosystem.config.js && pm2 save"
env PATH="$PATH:/usr/bin" pm2 startup systemd -u "$APP_USER" --hp "/home/$APP_USER" >/dev/null

echo "== nginx"
cp "$REPO_DIR/backend/deploy/matchup_proxy.conf" /etc/nginx/matchup_proxy.conf
cp "$REPO_DIR/backend/deploy/nginx.conf" /etc/nginx/sites-available/matchup
ln -sf /etc/nginx/sites-available/matchup /etc/nginx/sites-enabled/matchup
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "== git poll every minute (in case a webhook is missed)"
cat >/etc/cron.d/matchup-deploy <<EOF
* * * * * $APP_USER bash $REPO_DIR/backend/deploy/deploy.sh
EOF

echo "== firewall"
if ufw status 2>/dev/null | grep -q 'Status: active'; then
  ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 5432/tcp
fi

echo "== done"
sudo -u "$APP_USER" pm2 ls
