#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
set -eu
exec Rscript --vanilla "$1" "$2"
