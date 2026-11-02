#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# --no-gui and --no-window-system keep Octave to the terminal, --norc skips
# startup files, and --quiet drops the banner. The script reads the data path
# from argv().
set -eu
exec octave --no-gui --no-window-system --norc --quiet "$1" "$2"
