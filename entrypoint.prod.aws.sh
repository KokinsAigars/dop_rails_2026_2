#!/usr/bin/env bash
set -euo pipefail
# -e: stop on error
# -u: error on unset vars
# -o pipefail: fail pipeline if any command fails


APP_HOME="${APP_HOME:-/rails}"
RUN_MIGRATIONS="${RUN_MIGRATIONS:-1}"
WAIT_FOR_DB="${WAIT_FOR_DB:-1}"

# All runtime-writable dirs in one place
RUNTIME_DIRS=(
  "$APP_HOME/tmp"
  "$APP_HOME/storage"
  "$APP_HOME/log"
)

# Create dirs (works as root or as app user if permissions allow)
for d in "${RUNTIME_DIRS[@]}"; do
  mkdir -p "$d"
done

# If we start as root, fix ownership/perms (important for mounted volumes)
if [ "$(id -u)" = "0" ]; then
  chown -R app:app "${RUNTIME_DIRS[@]}"

  # Reasonable defaults for Rails runtime writable dirs
  chmod -R 775 "$APP_HOME/tmp" "$APP_HOME/storage" "$APP_HOME/log"

  # Optional: if you care about production.log existing with specific perms
  touch "$APP_HOME/log/production.log"
  chmod 664 "$APP_HOME/log/production.log" || true
fi


# Rails in containers: log to stdout
export RAILS_LOG_TO_STDOUT="${RAILS_LOG_TO_STDOUT:-1}"



# CONNECT TO DATABASE FUNCTION
wait_for_db() {
  # Read env with defaults / validation
  local host="${DATABASE_HOST:-}"
  local user="${DATABASE_USER:-}"
  local db="${DATABASE_NAME:-}"
  local timeout="${DB_WAIT_TIMEOUT:-60}"   # seconds

  if [ -z "$host" ] || [ -z "$user" ] || [ -z "$db" ]; then
    echo "DB env missing:"
    echo "  DATABASE_HOST='${DATABASE_HOST:-}'"
    echo "  DATABASE_USER='${DATABASE_USER:-}'"
    echo "  DATABASE_NAME='${DATABASE_NAME:-}'"
    exit 1
  fi

  echo "Waiting for PostgreSQL at ${host} (db=${db}, user=${user})..."

  export PGPASSWORD="${DATABASE_PASSWORD:-}"

  local start_ts
  start_ts="$(date +%s)"

  until psql -h "$host" -U "$user" -d "$db" -c '\q' >/dev/null 2>&1; do
    if [ $(( $(date +%s) - start_ts )) -ge "$timeout" ]; then
      echo "Timed out waiting for PostgreSQL after ${timeout}s" >&2
      return 1
    fi
    echo "Postgres is unavailable - sleeping"
    sleep 1
  done

  echo "Postgres is up!"
}

## DATABASE MIGRATION FUNCTION
run_migrations() {
  cd "$APP_HOME"

  if command -v flock >/dev/null 2>&1; then
    echo "Running db:migrate (with lock)..."
    flock -w 60 "$APP_HOME/tmp/db-migrate.lock" bundle exec rails db:migrate
  else
    echo "Running db:migrate (no lock)..."
    bundle exec rails db:migrate
  fi
}


# PID cleanup
mkdir -p "$APP_HOME/tmp/pids"
rm -f "$APP_HOME/tmp/pids/server.pid" || true


# Call connect to database function
if [ "${WAIT_FOR_DB}" = "1" ]; then
  wait_for_db
fi


# Call connect to run database migration function
if [ "${RUN_MIGRATIONS}" = "1" ]; then
  if [ "$(id -u)" = "0" ]; then
    su -s /bin/bash app -c "APP_HOME='$APP_HOME' $(declare -p DATABASE_HOST DATABASE_USER DATABASE_NAME DATABASE_PASSWORD 2>/dev/null); cd '$APP_HOME' && bundle exec rails db:migrate"
  else
    run_migrations
  fi
else
  echo "Skipping migrations (RUN_MIGRATIONS=${RUN_MIGRATIONS})"
fi



# Finally run the main process (server) as app
if [ "$(id -u)" = "0" ]; then
  exec su -s /bin/bash app -c "$(printf '%q ' "$@")"
else
  # run the main process passed from dockerfile CMD
  exec "$@"
fi


