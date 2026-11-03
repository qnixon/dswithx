#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# The script reads the data path from its arg table.
set -eu
exec lua5.4 "$1" "$2"
