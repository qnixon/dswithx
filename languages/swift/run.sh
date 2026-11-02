#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile into /tmp (the only writable path) with warnings as errors, then
# run with the data path.
set -eu
swiftc -O -warnings-as-errors -module-cache-path /tmp/module-cache -o /tmp/program "$1"
exec /tmp/program "$2"
