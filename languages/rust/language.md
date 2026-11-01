---
name: Rust
first_appeared: 2012
paradigm: Multi-paradigm (imperative, functional, generic)
toolchain: Rust 1.99.1
image: rust:1.99.1-slim-trixie
highlight: rust
---

Rust is a compiled systems language, built for the kind of work usually done
in C and C++, with a compiler that checks memory safety before the program
ever runs. Its data science libraries come as crates from crates.io, fetched
by the Cargo package manager. Here there are no crates: each implementation
is a single file compiled with `rustc` and nothing else, so everything comes
from the standard library. That library is deliberately small. It has
iterators, sorting, hash maps, and file reading, but nothing statistical, so
every formula is written out.

## Quirks

- The standard library has no CSV parser, so implementations here split each
  line on commas by hand (the data files have no quoted fields).
- `f64` isn't `Ord`, because NaN compares unequal to everything, so
  `values.sort()` won't compile. Use `sort_by(f64::total_cmp)` instead.
- There are no implicit numeric conversions: dividing an `f64` by a `usize`
  count is a compile error, so counts are converted with `as f64` first.
