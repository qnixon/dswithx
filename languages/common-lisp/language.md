---
name: Common Lisp
first_appeared: 1984
paradigm: Multi-paradigm, functional and object-oriented, dynamically typed
toolchain: SBCL 2.5.2
image: debian:trixie-20261027-slim + sbcl 2.5.2-1
highlight: common-lisp
---

Lisp dates from 1958, which makes it the second-oldest language family
still in use, after Fortran. For decades it was the language of artificial
intelligence research. Common Lisp, standardized in the 1980s and by ANSI in
1994, merged the dialects of that era into one. Here it runs on SBCL, a
compiler that turns each function into machine code.

Code and data share one shape: everything is a list, and `(+ 1 2)` calls `+`
with 1 and 2. The standard gives you lists, vectors, hash tables, `sort`,
`reduce`, a powerful `loop`, and `format`, but no statistics, no string
split, and no way to read command-line arguments. So each program reads
its data path from SBCL's own `sb-ext:*posix-argv*`, and nothing from
Quicklisp, the usual library installer, is installed.

## Quirks

- The reader turns `28.6` into a single float, accurate to about 7 digits:
  as a double it's 28.600000381469727. Every program here sets
  `*read-default-float-format*` to `double-float`, inside `eval-when` so
  that it also covers the decimals in the program itself, which the
  compiler reads before the program runs.
- `(/ 7 2)` is the exact fraction `7/2`, not 3 or 3.5. Integers never
  overflow: `(expt 2 100)` is 1267650600228229401496703205376.
- `sort` may take its list apart. After `(sort x #'<)` on `(5 4 3 2 1)`,
  `x` holds only `(4 5)`; the sorted list is what `sort` returns.
- Names are case-insensitive: `'Rosa` and `'rosa` are the same symbol.
  Strings aren't, and `string=` compares them.
- The run script compiles first and stops on any warning, so an unused
  variable or a discarded `sort` result fails the build.
