---
name: Pascal
first_appeared: 1970
paradigm: Imperative, structured, object-oriented
toolchain: Free Pascal 3.2.2
image: debian:trixie-20261027-slim + fp-compiler-3.2.2 3.2.2+dfsg-46
highlight: pascal
---

Niklaus Wirth designed Pascal at ETH Zurich in 1970 to teach structured
programming: blocks with `begin` and `end`, procedures and functions, and a
type for every variable, declared before use. Through the 1980s it was a
common first language in schools and universities, and Turbo Pascal and
later Delphi took it into commercial programs. Free Pascal is an
open-source compiler for the modern dialect, compiled here with every
warning treated as an error.

Its run-time library is larger than the language's reputation suggests:
`SysUtils` has string helpers such as `Split`, `Math` has `Mean` and
`Variance`, and `Generics.Collections` has growable lists and sorting. The
Free Component Library and Lazarus packages aren't installed here.

## Quirks

- The dialect depends on a mode switch. Without `{$mode objfpc}`, `Integer`
  is 16 bits and tops out at 32767; with it, `Integer` is 32 bits. Every
  program here starts with that switch.
- Without `{$H+}`, a `String` holds at most 255 characters and silently
  cuts off the rest.
- `/` always gives a real number, so `7 / 2` is 3.5. `div` is integer
  division, and `-7 div 2` is −3: it rounds toward zero.
- Strings count from 1, but dynamic arrays count from 0, and a fixed
  array counts from whatever its type says, such as `array[1..4]`.
- Range checks are off by default. With `V: array[1..4] of Double`,
  `V[0] := 5` won't compile, but `I := 0; V[I] := 5` runs with no error and
  writes outside the array.
- `WriteLn(x)` prints a real as `2.9677500000000002E+001`. `x:0:6` asks
  for width 0 and six decimals.
- `TDictionary` from `Generics.Collections` triggers warnings in the
  library's own code, so with warnings as errors, a program that uses it
  won't compile. `TList` and `TArrayHelper` compile cleanly.
- Names aren't case-sensitive: `LENGTH(S)` and `Length(s)` are the same
  call.
