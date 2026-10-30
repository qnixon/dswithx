#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
set -eu
exec awk -f "$1" "$2"
