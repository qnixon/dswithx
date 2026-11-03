#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# The script reads the data path from System.argv(). HOME points at /tmp
# because the root filesystem is read-only, and the UTF-8 locale lets
# messages print their box-drawing characters.
# Elixir's --warnings-as-errors doesn't apply to scripts, so this script
# holds the output and fails the run if the compiler printed any warning.
set -eu
export HOME=/tmp LANG=C.UTF-8
status=0
elixir "$1" "$2" >/tmp/output 2>/tmp/errors || status=$?
if [ "$status" -ne 0 ] || grep -q 'warning:' /tmp/errors; then
  cat /tmp/errors >&2
  exit 1
fi
cat /tmp/errors >&2
cat /tmp/output
