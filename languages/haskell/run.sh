#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile into /tmp (the only writable path), then run with the data path.
# GHC writes its intermediate files next to the source unless told otherwise,
# and the source folder is read-only, so -outputdir sends them to /tmp too.
set -eu
ghc -O1 -Wall -Werror -v0 -outputdir /tmp/build -o /tmp/program "$1"
exec /tmp/program "$2"
