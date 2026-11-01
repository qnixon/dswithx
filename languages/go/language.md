---
name: Go
first_appeared: 2009
paradigm: Imperative, concurrent
toolchain: Go 1.27.3
image: golang:1.27.3-trixie
highlight: go
---

Go was designed at Google for large server programs, and it is better known
for web services and command-line tools than for data science. It is
compiled and statically typed, but small enough to read without much
practice. The standard library has CSV parsing, math, and sorting, but no
statistics package, so there is nothing to avoid here: every formula is
written out as a loop. Each program is a single `main.go` with no `go.mod`
file, so it can import only the standard library, and the runner compiles it
into `/tmp` before running it.

## Quirks

- Go never converts between number types on its own: dividing a `float64` by
  an `int` is a compile error, so counts are wrapped in `float64(n)`.
- An unused import or local variable is a compile error, not a warning.
- Map iteration order is randomized and changes from run to run, so code
  that needs a fixed order sorts the keys first.
