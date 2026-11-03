#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# GNAT names the main procedure after its file and writes its build files
# next to the source, so this compiles a copy, /tmp/main.adb, whose
# procedure is Main. -gnatwa turns on most warnings, and -gnatwe makes them
# errors.
set -eu
cp "$1" /tmp/main.adb
cd /tmp
gnatmake-14 -q -gnat2022 -gnatwa -gnatwe -O2 -o /tmp/program main.adb >/tmp/compile.log 2>&1 || { cat /tmp/compile.log >&2; exit 1; }
exec /tmp/program "$2"
