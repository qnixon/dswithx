#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
set -eu
cd /tmp  # GNU APL writes its input history to the working directory
exec apl --script --noColor --silent -f "$1" -- "$2"
