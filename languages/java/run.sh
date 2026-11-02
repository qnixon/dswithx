#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile into /tmp (the only writable path) with every lint warning turned
# into an error, then run the class named Main with the data path.
set -eu
javac -Xlint:all -Werror -d /tmp/classes "$1"
exec java -cp /tmp/classes Main "$2"
