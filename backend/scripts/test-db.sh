#!/usr/bin/env bash
# Applies the migration and seed to a throwaway Postgres database and runs the RLS/integration checks.
# Needs a local Postgres 15+ superuser connection, e.g. PGHOST=localhost PGUSER=postgres.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
db="${TEST_DB:-spag_buddy_test}"

dropdb --if-exists "$db"
createdb "$db"
trap 'dropdb --if-exists "$db"' EXIT

run() { psql -v ON_ERROR_STOP=1 -q -X -d "$db" "$@"; }

run -f "$here/supabase-stub.sql"
run -f "$here/../supabase/migrations/20260930000000_init.sql"
run -f "$here/../supabase/seed.sql"
run -f "$here/test-db.sql"
echo "Database checks passed"
