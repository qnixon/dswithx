---
name: APL
first_appeared: 1966
paradigm: Array
toolchain: GNU APL 2.0
image: debian:trixie-20261027-slim + GNU APL 2.0 (built from source)
highlight: apl
---

APL began as Kenneth Iverson's mathematical notation, published in his 1962
book *A Programming Language*, and was first implemented at IBM as APL\360
in 1966. Every function works on whole arrays, and most are a single glyph,
so a sum is `+/X`, a mean is `(+/X)÷≢X`, and a program that would be a page
of loops elsewhere fits in a few lines. GNU APL has a `⎕MX` statistics and
matrix function when it is built with GSL, a third-party library; GSL isn't
installed, so `⎕MX` isn't available here. GNU APL is the GNU project's free
interpreter of ISO standard APL with nested arrays. The runner executes
each `main.apl` as a script, and the comments explain every line for
readers new to APL.

## Quirks

- Expressions run right to left with no operator precedence: `2×3+4` is 14,
  and `10-5-2` is 7.
- Negative numbers are written with a high minus, `¯3`, which is not the
  `-` function. `⍕` prints `¯` too, and its fixed-decimal format drops the
  leading zero (`0 6⍕0.94` gives `.940000`), so each program formats its
  own output.
- Indexing starts at 1, set by the system variable `⎕IO` (index origin).
- In GNU APL a `{}` function fits on one line, so longer functions use the
  older `∇` definitions and jump to labels with `→` to loop.
