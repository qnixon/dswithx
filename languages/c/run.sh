#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile into /tmp (the only writable path), then run with the data path.
# -lm links the math library, which C keeps separate from the rest.
set -eu
gcc-14 -std=c17 -O2 -Wall -Wextra -pedantic -Werror -o /tmp/program "$1" -lm
exec /tmp/program "$2"
