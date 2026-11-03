---
name: Tcl
first_appeared: 1988
paradigm: Imperative, scripting, command-based
toolchain: Tcl 9.0.1
image: debian:trixie-20261027-slim + tcl9.0 9.0.1+dfsg-2
highlight: tcl
---

Tcl (Tool Command Language, often said "tickle") was created by John
Ousterhout at UC Berkeley in 1988 as a small language to embed in other
programs. With its Tk toolkit it became a quick way to build desktop
interfaces, and it still runs inside chip-design tools, network test
equipment, and Expect, the classic tool for scripting interactive
programs.

Tcl has almost no syntax. Every line is a command followed by its
arguments, and every value is a string. `$name` substitutes a variable,
`[command]` runs a command and substitutes its result, and `{braces}` quote
text without substituting anything. Even `if` and `while` are ordinary
commands that take their bodies as braced strings. Arithmetic happens only
inside `expr`. Lists and dictionaries are built in; Tcllib, the large
add-on library with statistics and matrix packages, isn't installed here.

## Quirks

- `lsort` compares text unless told otherwise, so `lsort {3.5 1.25 2 10}`
  gives `1.25 10 2 3.5`. `lsort -real` sorts them as numbers.
- Brace your expressions. With `set x "1 + 2"`, `expr $x` gives 3, because
  Tcl substitutes `$x` first and `expr` then reads the text as code.
  `expr {$x}` gives back the string `1 + 2`.
- `7 / 2` is 3, and `-7 / 2` is −4: integer division rounds down, not
  toward zero. `7 / 2.0` is 3.5.
- `foreach x {1 2 3} y {a b}` walks both lists in step, and when one runs
  out, it pads with empty strings instead of stopping: the last pass gets
  `x` = 3 and an empty `y`.
- Integers never overflow: `2**70` is 1180591620717411303424.
- `==` compares numbers when it can: `"10" == "10.0"` is true, while
  `string equal 10 10.0` is false.
