---
name: Java
first_appeared: 1995
paradigm: Object-oriented, imperative, statically typed
toolchain: OpenJDK 21
image: debian:trixie-20261027-slim + openjdk-21-jdk-headless 21.0.12.1
highlight: java
---

Java came out of Sun Microsystems in 1995 with the promise "write once, run
anywhere": it compiles to bytecode for the Java virtual machine, not for one
kind of processor. It's one of the most-used languages in the world, mostly
in business systems and Android apps. Data science reaches it through the
big-data tools built on the JVM, such as Hadoop, Spark, and Kafka.

Its standard library is large, with collections, streams, and file and
date handling, but it has no statistics or matrices, so the methods here are
written out by hand. The implementations use no build tool and no
third-party library: each is one file, compiled with `javac` and run with
`java`. Libraries such as Apache Commons Math aren't installed.

## Quirks

- `==` compares objects, not their contents. `new String("rosa") == "rosa"`
  is false; `.equals("rosa")` is true.
- The same goes for boxed numbers, with a twist: two `Integer`s holding 127
  are `==`, but two holding 1000 aren't, because Java reuses the small ones.
- `printf` follows the computer's language settings, so on a German system
  `%.6f` prints 29,677500. Every program here passes `Locale.ROOT`.
- A method that can throw a checked exception, such as `IOException` when
  reading a file, must say `throws IOException` or catch it, or the file
  won't compile.
- `int` arithmetic wraps without warning: `Integer.MAX_VALUE + 1` is
  −2147483648. `-7 / 2` is −3; `Math.floorDiv(-7, 2)` is −4.
