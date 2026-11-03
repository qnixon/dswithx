---
name: Lua
first_appeared: 1993
paradigm: Imperative, scripting, multi-paradigm
toolchain: Lua 5.4.7
image: debian:trixie-20261027-slim + lua5.4 5.4.7-1+b2
highlight: lua
---

Lua (Portuguese for "moon") was created in 1993 at the Pontifical Catholic
University of Rio de Janeiro by Roberto Ierusalimschy, Luiz Henrique de
Figueiredo, and Waldemar Celes. It was built to be embedded in larger
programs, and it's small and fast enough that it now runs inside game
engines, Roblox, the Neovim editor, and network tools.

Lua has one data structure, the table. The same table type serves as an
array, a dictionary, a record, and an object, depending on which keys you
use. Arrays are tables whose keys are 1, 2, 3, and so on, and `#t` gives
their length. The standard library is small: string patterns, `table.sort`,
`math`, and file input and output. There's no split, no round, and no CSV
reader, and modules from LuaRocks, Lua's package manager, aren't installed
here.

## Quirks

- Indexes start at 1. With `a = {10, 20, 30}`, `a[1]` is 10 and `a[0]` is
  `nil`, not an error.
- `0` and the empty string are true. Only `nil` and `false` are false, so
  `0 and "yes" or "no"` gives "yes".
- `/` always gives a float, so `10 / 2` is `5.0`. `//` divides and rounds
  down: `7 // 2` is 3, and `-7 // 2` is −4.
- Not equal is `~=`, not `!=`.
- `table.sort` isn't stable, so rows with equal keys can come out in any
  order. Its comparison must be a strict "less than": sorting with
  `a <= b` can stop with "invalid order function for sorting".
- `#` is only reliable on an array with no gaps. With `h[1]`, `h[2]`, and
  `h[4]` set, `#h` gave 4, although `h[3]` is `nil`.
- Integers wrap around when they overflow: `math.maxinteger + 1` is
  `math.mininteger`.
- `1` and `1.0` are the same table key, so setting `d[1.0]` overwrites
  `d[1]`.
