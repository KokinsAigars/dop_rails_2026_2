#!/usr/bin/env bash
set -euo pipefail

# ---  ---
: "${RAILS_PORT:=3000}"
: "${VITE_PORT:=3040}"
: "${VITE_HOST:=0.0.0.0}"
: "${VITE_BASE:=/vite-assets/}"
VITE_BASE="${VITE_BASE%/}/"

export VITE_RUBY_DEV_SERVER_URL="http://127.0.0.1:${VITE_PORT}"

rm -f tmp/pids/server.pid || true


# ---------------------------------------------
# Start Vite Server in the Background
# ---------------------------------------------
echo "[entrypoint] Starting Vite server on ${VITE_HOST}:${VITE_PORT}..."

npx vite --host 0.0.0.0 --port "${VITE_PORT}" &

VITE_PID=$!

trap "kill $VITE_PID || true" EXIT

# --- Wait for Vite Health Check ---
VITE_CHECK_URL="http://127.0.0.1:${VITE_PORT}/vite-assets/@vite/client"
echo -n "[entrypoint] Waiting for Vite health check at ${VITE_CHECK_URL}"

for i in $(seq 1 80); do
  code=$(curl -s -f -o /dev/null -w "%{http_code}" "${VITE_CHECK_URL}" || true)
  if [ "$code" = "200" ] || [ "$code" = "304" ]; then
    echo " OK (HTTP $code)"
    break
  fi
  echo -n "."
  sleep 0.25
done

if [ "$code" != "200" ] && [ "$code" != "304" ]; then
  echo "" # Newline after all the dots
  echo "[entrypoint] ERROR: Vite server failed to respond after 20 seconds. Aborting."
  exit 1
fi


# ---------------------------------------------
# Database Setup
# ---------------------------------------------
: "${DATABASE_HOST:=db_dop_dev}"
: "${DATABASE_PORT:=5432}"
: "${DATABASE_USER:=dop_dev}"
: "${POSTGRES_DB:=dop_dev}"

echo "[entrypoint] Running database setup..."
echo "[entrypoint] DATABASE_HOST: '${DATABASE_HOST}'"
echo "[entrypoint] DATABASE_PORT: '${DATABASE_PORT}'"
echo "[entrypoint] DATABASE_USER: '${DATABASE_USER}'"
echo "[entrypoint] POSTGRES_DB:   '${POSTGRES_DB}'"
echo "[entrypoint] Waiting for database at ${DATABASE_HOST}:${DATABASE_PORT}..."

if command -v getent > /dev/null; then
  echo "[entrypoint] Resolving ${DATABASE_HOST}..."
  getent hosts "$DATABASE_HOST" || echo "[entrypoint] Could not resolve ${DATABASE_HOST}"
fi

until pg_isready -h "$DATABASE_HOST" -p "$DATABASE_PORT"; do
  echo -n "."
  sleep 1
done
echo " DB is READY!"

if ! bundle exec rails db:version > /dev/null 2>&1; then
  echo "[entrypoint] Database not found or not initialized. Attempting to create..."
  bundle exec rails db:create || echo "[entrypoint] Database might already exist or creation failed."
fi

echo "[entrypoint] Rails environment check..."
bundle exec rails runner 'puts "Connected to: #{ActiveRecord::Base.connection.current_database}"'

echo "[entrypoint] Running migrations..."
bundle exec rails db:migrate


# ---------------------------------------------
# Start Rails Server (Foreground)
# ---------------------------------------------
echo "[entrypoint] Starting Rails server on 0.0.0.0:${RAILS_PORT}"

exec bundle exec rails s -b 0.0.0.0 -p "${RAILS_PORT}"

