#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile into /tmp (the only writable path), treating every warning as an
# error, then run with the data path.
set -eu
fpc -Sew -O2 -FE/tmp -o/tmp/program "$1" >/tmp/compile.log || { cat /tmp/compile.log >&2; exit 1; }
exec /tmp/program "$2"
