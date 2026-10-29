#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
set -eu
exec python3 "$1" "$2"
