#!/bin/bash
# Lidi Studio — Postgres initialization
# Creates 5 logical databases for service isolation.
# Runs once on first container start (when /var/lib/postgresql/data is empty).

set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
  CREATE DATABASE "${POSTGRES_DB_GHOST}";
  CREATE DATABASE "${POSTGRES_DB_CALCOM}";
  CREATE DATABASE "${POSTGRES_DB_DOCUSEAL}";
  CREATE DATABASE "${POSTGRES_DB_NOCODB}";
  CREATE DATABASE "${POSTGRES_DB_UMAMI}";
EOSQL

echo "Created databases: ${POSTGRES_DB_GHOST}, ${POSTGRES_DB_CALCOM}, ${POSTGRES_DB_DOCUSEAL}, ${POSTGRES_DB_NOCODB}, ${POSTGRES_DB_UMAMI}"
