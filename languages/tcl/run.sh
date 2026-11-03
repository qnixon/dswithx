#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# The script reads the data path from its argv list.
set -eu
exec tclsh9.0 "$1" "$2"
