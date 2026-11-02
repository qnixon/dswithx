#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# bwbasic 2.20 has no way to read command-line arguments, so the data path
# goes in the DATA environment variable, which programs read with ENVIRON$.
# bwbasic prints a banner first, and it exits with status 0 even when a
# program fails, so this script drops the banner and checks the output.
set -eu
DATA="$2" bwbasic "$1" </dev/null >/tmp/output
# The banner's four lines each start with a carriage return.
sed '/^\r/d' /tmp/output >/tmp/clean
# A program that finishes runs SYSTEM and exits. One that stops early, on an
# error or a statement bwbasic doesn't know, leaves its bwBASIC: prompt.
if grep -q -e '^ERROR' -e 'bwBASIC:' /tmp/clean; then
  cat /tmp/clean >&2
  exit 1
fi
cat /tmp/clean
