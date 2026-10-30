#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
#
# Starts a throwaway PostgreSQL server in /tmp (the only writable path), loads
# the data file into a table named "data" with one column per CSV header
# (numeric columns become double precision, others stay text) plus row_id,
# numbering rows in file order from 1, runs the SQL file, and prints each
# result row of its final query as "name value".
set -eu

export PGDATA=/tmp/pgdata PGHOST=/tmp PGUSER=postgres PGDATABASE=postgres

initdb --auth=trust --username=postgres --no-instructions >/dev/null
pg_ctl start --wait --silent --log=/tmp/postgres.log \
  --options="-c listen_addresses= -c unix_socket_directories=/tmp -c fsync=off" >/dev/null

header=$(head -n 1 "$2" | tr -d '\r')
columns=$(printf '%s\n' "$header" | awk -F, '{ for (i = 1; i <= NF; i++) printf ", \"%s\" text", $i }')
names=$(printf '%s\n' "$header" | awk -F, '{ for (i = 1; i <= NF; i++) printf "%s\"%s\"", (i > 1 ? ", " : ""), $i }')

psql --quiet --no-psqlrc -v ON_ERROR_STOP=1 >/dev/null <<SQL
-- Tables have no row order, so row_id records file order: \copy inserts rows
-- in file order, and the identity column numbers them as they arrive.
CREATE TABLE data (row_id integer GENERATED ALWAYS AS IDENTITY$columns);
\copy data ($names) FROM '$2' WITH (FORMAT csv, HEADER true)
DO \$\$
DECLARE c text;
BEGIN
  FOR c IN SELECT column_name FROM information_schema.columns WHERE table_name = 'data' AND column_name <> 'row_id' LOOP
    BEGIN
      EXECUTE format('ALTER TABLE data ALTER COLUMN %I TYPE double precision USING %I::double precision', c, c);
    EXCEPTION WHEN others THEN
      NULL; -- not numeric: keep it as text
    END;
  END LOOP;
END
\$\$;
SQL

exec psql --quiet --no-psqlrc -v ON_ERROR_STOP=1 \
  --tuples-only --no-align --field-separator=' ' --file="$1"
