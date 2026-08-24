#!/usr/bin/env bash
# Local security/authorization test run against a bare PostgreSQL.
set -euo pipefail
DB=${DB:-ede_test}
su postgres -c "dropdb --if-exists $DB" 2>/dev/null || true
su postgres -c "createdb $DB"
for f in tests/00_shim_local_only.sql migrations/*.sql tests/01_helpers_local_only.sql; do
  echo "--- $f"
  su postgres -c "psql -v ON_ERROR_STOP=1 -q -d $DB -f $(pwd)/$f"
done
for t in tests/*.test.sql; do echo "=== $t"; su postgres -c "psql -d $DB -f $(pwd)/$t"; done
