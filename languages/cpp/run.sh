#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile into /tmp (the only writable path) as C++23 with warnings as
# errors, then run with the data path.
set -eu
g++-14 -std=c++23 -O2 -Wall -Wextra -pedantic -Werror -o /tmp/program "$1"
exec /tmp/program "$2"
