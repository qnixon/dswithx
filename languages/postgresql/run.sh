#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
#
# Starts a throwaway PostgreSQL server in /tmp (the only writable path), loads
# the data file into a table named "data" with one column per CSV header
# (numeric columns become double precision, others stay text), runs the SQL
# file, and prints each result row of its final query as "name value".
set -eu

export PGDATA=/tmp/pgdata PGHOST=/tmp PGUSER=postgres PGDATABASE=postgres

initdb --auth=trust --username=postgres --no-instructions >/dev/null
pg_ctl start --wait --silent --log=/tmp/postgres.log \
  --options="-c listen_addresses= -c unix_socket_directories=/tmp -c fsync=off" >/dev/null

columns=$(head -n 1 "$2" | tr -d '\r' |
  awk -F, '{ for (i = 1; i <= NF; i++) printf "%s\"%s\" text", (i > 1 ? ", " : ""), $i }')

psql --quiet --no-psqlrc -v ON_ERROR_STOP=1 >/dev/null <<SQL
CREATE TABLE data ($columns);
\copy data FROM '$2' WITH (FORMAT csv, HEADER true)
DO \$\$
DECLARE c text;
BEGIN
  FOR c IN SELECT column_name FROM information_schema.columns WHERE table_name = 'data' LOOP
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
