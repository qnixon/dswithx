---
name: Haskell
first_appeared: 1990
paradigm: Purely functional, lazy, statically typed
toolchain: GHC 9.6.6
image: debian:trixie-20261027-slim + ghc 9.6.6-4
highlight: haskell
---

Haskell was designed by a committee of researchers and published in 1990,
to give the many lazy functional languages of the time one common
standard. It's the only purely functional language on this site: there are
no loops and no variables that change, so a value, once defined, stays put.
Repetition comes from recursion, folds such as `sum` and `foldl'`, and list
comprehensions. Here it is compiled with GHC, with every warning turned
into an error.

We use only `base`, the library every Haskell program starts with. GHC
also installs a few separate packages, such as `containers` for maps, but
like Ruby's bundled gems they aren't part of the standard library, so we
leave them out and keep counts in plain lists. There's no CSV reader and no
statistics, and splitting a string on commas means writing a small
function. The `split`, `vector`, and `statistics` packages from Hackage,
Haskell's package archive, aren't installed.

## Quirks

- Haskell is lazy: nothing is computed until it's needed.
  `take 3 (map (*2) [1 ..])` maps over an endless list and returns
  `[2,4,6]`.
- Input and output happen only inside `IO` actions, in a `do` block. The
  pure code can't print or read files, so `main` reads the data and hands
  it over.
- `div` rounds down, so `` (-7) `div` 2 `` is −4; `quot` rounds toward zero
  and gives −3. Without the parentheses, `` -7 `div` 2 `` means
  `` -(7 `div` 2) ``, which is −3.
- `head` of an empty list crashes at run time with
  "Prelude.head: empty list".
