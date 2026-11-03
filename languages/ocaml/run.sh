#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# The source directory is read-only, and ocamlopt writes its build files next
# to the source, so it compiles a copy in /tmp. Any warning fails the build.
set -eu
cp "$1" /tmp/main.ml
cd /tmp
ocamlopt -warn-error +a -o /tmp/program main.ml >/tmp/compile.log 2>&1 || { cat /tmp/compile.log >&2; exit 1; }
exec /tmp/program "$2"
