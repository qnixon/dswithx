#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
set -eu
exec node "$1" "$2"
