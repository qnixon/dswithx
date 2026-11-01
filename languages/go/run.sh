#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile into /tmp (the only writable path), then run with the data path.
set -eu
go build -o /tmp/program "$1"
exec /tmp/program "$2"
