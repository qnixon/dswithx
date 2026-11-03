#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# The script reads the data path from $argv[1]. PHP prints warnings and
# keeps going, so they are reported on stderr and fail the run.
set -eu
status=0
php -d display_errors=stderr -d log_errors=0 -d error_reporting=-1 "$1" "$2" >/tmp/output 2>/tmp/errors || status=$?
if [ "$status" -ne 0 ] || [ -s /tmp/errors ]; then
  cat /tmp/errors >&2
  exit 1
fi
cat /tmp/output
