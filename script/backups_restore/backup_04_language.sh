#!/usr/bin/env bash
set -euo pipefail

DATE=$(date +%Y_%m_%d)

SCHEMA_NAME="sc_04_language"
DUMP_FILE="backups/${SCHEMA_NAME}_${DATE}.dump"

DB_HOST="localhost"
DB_PORT="5433"
DB_USER="dop_dev"
DB_NAME="dop_dev"

pg_dump \
  -h "${DB_HOST}" \
  -p "${DB_PORT}" \
  -U "${DB_USER}" \
  --format=custom \
  --schema="${SCHEMA_NAME}" \
  --data-only \
  --no-owner --no-privileges \
  --file "${DUMP_FILE}" \
  "${DB_NAME}"

# Verify it exists and is not empty
if [[ ! -s "${DUMP_FILE}" ]]; then
  echo "ERROR: dump file not created or empty: ${DUMP_FILE}" >&2
  exit 1
fi

sha256sum "${DUMP_FILE}" > "${DUMP_FILE}.sha256"
echo "OK: wrote checksum ${DUMP_FILE}.sha256"

# export PGPASSWORD='2WlOsZw6QLPQXI3k'

