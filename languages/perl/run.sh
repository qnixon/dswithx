#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# The script reads the data path from @ARGV. Perl prints warnings and keeps
# going, so the run fails if anything was written to stderr.
set -eu
status=0
perl "$1" "$2" >/tmp/output 2>/tmp/errors || status=$?
if [ "$status" -ne 0 ] || [ -s /tmp/errors ]; then
  cat /tmp/errors >&2
  exit 1
fi
cat /tmp/output
