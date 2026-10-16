#!/usr/bin/env bash
# Pulls the latest main and rebuilds/restarts ONLY the modules whose files changed.
#
#   backend/apps/<module>/**          -> that module only
#   backend/libs/**, tsconfig, nest-cli.json, deploy/ecosystem.config.js -> every module
#   backend/package.json / package-lock.json -> npm ci, then every module
#   anything outside backend/ (the Flutter app) -> nothing
#
# Usage: deploy.sh            (called by the webhook and the 1-minute cron)
#        deploy.sh --all      (rebuild everything)
#        deploy.sh forum      (rebuild one module by hand)
set -uo pipefail

REPO_DIR="${REPO_DIR:-/opt/matchup}"
BACKEND="$REPO_DIR/backend"
LOG="${DEPLOY_LOG:-/var/log/matchup/deploy.log}"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1

# One deploy at a time; a push that lands meanwhile is picked up by the next run.
exec 9>/tmp/matchup-deploy.lock
flock 9

source "$BACKEND/deploy/modules.sh"
stamp() { date '+%Y-%m-%d %H:%M:%S'; }

cd "$REPO_DIR"
OLD=$(git rev-parse HEAD)
git fetch --quiet origin main || { echo "$(stamp) git fetch failed"; exit 1; }
git reset --quiet --hard origin/main
NEW=$(git rev-parse HEAD)

TARGETS=()
if [[ "${1:-}" == "--all" ]]; then
  TARGETS=("${MODULES[@]}")
elif [[ -n "${1:-}" ]]; then
  TARGETS=("$1")
elif [[ "$OLD" != "$NEW" ]]; then
  CHANGED=$(git diff --name-only "$OLD" "$NEW" -- backend/)
  [[ -z "$CHANGED" ]] && { echo "$(stamp) $NEW: no backend change"; exit 0; }
  echo "$(stamp) ${OLD:0:7} -> ${NEW:0:7}: $(git log -1 --format='%an: %s' "$NEW")"

  if grep -qE '^backend/package(-lock)?\.json$' <<<"$CHANGED"; then
    echo "$(stamp) dependencies changed: npm ci"
    (cd "$BACKEND" && npm ci --no-audit --no-fund) || { echo "$(stamp) npm ci FAILED"; exit 1; }
    TARGETS=("${MODULES[@]}")
  elif grep -qE '^backend/(libs/|tsconfig[^/]*\.json$|nest-cli\.json$|deploy/ecosystem\.config\.js$)' <<<"$CHANGED"; then
    echo "$(stamp) shared code changed: every module"
    TARGETS=("${MODULES[@]}")
  else
    for m in "${MODULES[@]}"; do
      grep -q "^backend/apps/$m/" <<<"$CHANGED" && TARGETS+=("$m")
    done
  fi
  # A webhook change restarts the webhook itself.
  grep -q '^backend/deploy/webhook.js$' <<<"$CHANGED" && pm2 restart webhook >/dev/null
fi

[[ ${#TARGETS[@]} -eq 0 ]] && { echo "$(stamp) nothing to rebuild"; exit 0; }

cd "$BACKEND"
for m in "${TARGETS[@]}"; do
  echo "$(stamp) [$m] building"
  if npx nest build "$m" >"/var/log/matchup/build-$m.log" 2>&1; then
    pm2 startOrReload deploy/ecosystem.config.js --only "$m" >/dev/null
    echo "$(stamp) [$m] restarted OK"
  else
    echo "$(stamp) [$m] BUILD FAILED, still running the previous version:"
    tail -n 20 "/var/log/matchup/build-$m.log"
  fi
done
pm2 save >/dev/null
