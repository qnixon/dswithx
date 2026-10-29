#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
set -eu
exec ruby "$1" "$2"
