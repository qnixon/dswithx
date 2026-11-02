#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile into /tmp (the only writable path), then run with the data path.
set -eu
gfortran-14 -std=f2018 -O2 -o /tmp/program "$1"
exec /tmp/program "$2"
