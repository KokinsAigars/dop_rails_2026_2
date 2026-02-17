#!/usr/bin/env bash
set -euo pipefail

SCHEMA_NAME="public"
DATE="2026_01_23"
DUMP_FILE="backups/${SCHEMA_NAME}_${DATE}.dump"

DB_HOST="localhost"
DB_PORT="5433"
DB_USER="dop_dev"
DB_NAME="dop_dev"

if [[ ! -f "${DUMP_FILE}" ]]; then
  echo "ERROR: dump file not found: ${DUMP_FILE}" >&2
  exit 1
fi

if [[ -f "${DUMP_FILE}.sha256" ]]; then
  sha256sum -c "${DUMP_FILE}.sha256" \
    || { echo "ERROR: checksum mismatch"; exit 1; }
fi

pg_restore -l "${DUMP_FILE}" >/dev/null \
  || { echo "ERROR: invalid dump file"; exit 1; }

echo "Restoring schema ${SCHEMA_NAME} into ${DB_NAME} (${DB_HOST}:${DB_PORT})"

pg_restore \
  -h "${DB_HOST}" \
  -p "${DB_PORT}" \
  -U "${DB_USER}" \
  --dbname="${DB_NAME}" \
  --schema="${SCHEMA_NAME}" \
  --data-only \
  --no-owner --no-privileges \
  --disable-triggers \
  --section=data \
  -T "ar_internal_metadata" \
  -T "schema_migrations" \
  "${DUMP_FILE}"

#  --clean \
#  --if-exists \

echo "OK: restore completed"

# chmod +x script/restore_01_abbreviations_dev.sh
# export PGPASSWORD='2WlOsZw6QLPQXI3k'
