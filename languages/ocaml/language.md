---
name: OCaml
first_appeared: 1996
paradigm: Functional, imperative, statically typed
toolchain: OCaml 5.3.0
image: debian:trixie-20261027-slim + ocaml 5.3.0-3
highlight: ocaml
---

OCaml was released in 1996 at INRIA, the French national computer science
institute, by Xavier Leroy, Jérôme Vouillon, Damien Doligez, Didier Rémy,
and others. It grew from the ML family of languages, first built in the
1970s to write proofs about programs. The trading firm Jane Street writes
most of its software in it, and the Rocq proof assistant (formerly Coq) is
written in it.

Like Haskell, OCaml is functional and checks every type before the program
runs, working most of them out on its own. Unlike Haskell, it runs each
line in order, and it lets you use loops and change arrays in place when
that's clearer. The standard library has lists, arrays, hash tables,
sorting, and file reading. Packages from opam, OCaml's package manager,
aren't installed here. The run script compiles each program to native code
with `ocamlopt` and treats every warning as an error.

## Quirks

- Integers and floats never mix, and floats have their own operators:
  `+.`, `-.`, `*.`, and `/.`. `1 + 2.0` doesn't compile; you convert with
  `float_of_int`.
- Integer `/` rounds toward zero, so `-7 / 2` is −3, and `-7 mod 3` is −1.
- `=` compares structure and `==` compares identity: `[1; 2] = [1; 2]` is
  true, while `[|1|] == [|1|]` is false.
- `string_of_float 3.` gives `"3."`, with no zero after the point.
  `Printf.printf "%.6f"` prints six decimals.
- A `match` that misses a case gets a warning, so here it doesn't compile:
  `function 0 -> "zero" | 1 -> "one"` stops with "this pattern-matching is
  not exhaustive".
- An unused variable is a warning too, so it also stops the build.
- Integers wrap around when they overflow: `max_int + 1 = min_int` is true.
- Reading past the end of an array raises
  `Invalid_argument("index out of bounds")` instead of reading memory.
