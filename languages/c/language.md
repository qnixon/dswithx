---
name: C
first_appeared: 1972
paradigm: Imperative, procedural
toolchain: GCC 14.2
image: debian:trixie-20261027-slim + gcc-14 14.2.0-19
highlight: c
---

C came out of Bell Labs in 1972, written to build the Unix operating
system, and most of computing still rests on it: Python, R, PostgreSQL, and
the core of NumPy are all written largely in C. Here it is compiled with
GCC using the C17 standard, with every warning turned into an error.

Its standard library is small. It has `sqrt`, `log`, and `exp`, `qsort` for
sorting, and `printf` for output, but no growable arrays, no hash tables,
no CSV reader, and no string type beyond an array of characters. So the
implementations do their own bookkeeping: they grow arrays with `realloc`,
split lines with `strtok`, and release memory with `free`, because nothing
does it for you.

## Quirks

- The math functions live in a separate library. Without `-lm` on the
  compile line, a call to `log` fails with "undefined reference to `log`".
- An array passed to a function arrives as a bare pointer, so it forgets its
  length. `sizeof` on a three-`int` array gives 12 bytes where it's
  declared, and 8, the size of a pointer, inside the function.
- `7 / 2` is integer division, giving 3, and `-7 / 2` gives −3: C rounds
  toward zero.
- Unsigned numbers wrap around: an `unsigned int` holding 0, minus 1, is
  4294967295. Sizes and counts (`size_t`) are unsigned, so a loop that
  counts down to 0 needs care.
