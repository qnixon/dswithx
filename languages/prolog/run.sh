#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Load the program, stopping on any warning or error, and run its main/0;
# the program reads the data path from its command-line arguments.
set -eu
exec swipl --on-warning=halt --on-error=halt "$1" "$2"
