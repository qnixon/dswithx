#!/bin/sh
# Run contract: run.sh <source-file> <data-file>
# Compile first, with the compiler's messages sent to stderr, and stop if it
# reports any warning, style warnings included. Then run the compiled file
# as a script; the program reads the data path from sb-ext:*posix-argv*.
set -eu
sbcl --noinform --non-interactive --no-sysinit --no-userinit \
  --eval '(setf *compile-verbose* nil *compile-print* nil)' \
  --eval "(multiple-value-bind (fasl warnings failure)
              (compile-file \"$1\" :output-file \"/tmp/main.fasl\")
            (declare (ignore fasl))
            (sb-ext:exit :code (if (or warnings failure) 1 0)))" >&2
exec sbcl --script /tmp/main.fasl "$2"
