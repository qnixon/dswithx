#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
set -eu
exec julia --startup-file=no "$1" "$2"
