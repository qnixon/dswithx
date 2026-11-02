---
name: BASIC
first_appeared: 1964
paradigm: Imperative, unstructured
toolchain: Bywater BASIC 2.20
image: debian:trixie-20261027-slim + bwbasic 2.20pl2-14
highlight: basic
---

BASIC (Beginner's All-purpose Symbolic Instruction Code) was created at
Dartmouth College in 1964 by John Kemeny and Thomas Kurtz, so that students
who weren't scientists could write programs. A version of it came built into
most home computers of the late 1970s and 1980s, and for many people it was
their first language. Here it runs in Bywater BASIC, an interpreter for the
classic line-numbered style.

Every line has a number, and the program runs in number order. `GOTO`
jumps to a line, and `GOSUB` jumps to a subroutine, a block of lines that
ends in `RETURN`. Subroutines take no arguments, and every variable is
global, so the programs here pass values by setting variables before each
`GOSUB`. A name ending in `$`, such as `L$`, holds text. There's no sort,
no growable array, and no CSV reader, so the implementations write their
own.

## Quirks

- Every array needs a `DIM` with a fixed size before it's used. `A(3) = 1`
  on an undeclared `A` stops the program with "Assignment must be to
  variable".
- `\` isn't integer division here: `7 \ 2` gives 3.5. `INT(7 / 2)` gives 3.
- Numbers are stored in double precision, but `PRINT` shows only about
  seven digits: `SQR(2)` prints as 1.4142136. So `0.1 + 0.2` prints 0.3 yet
  isn't equal to 0.3. `PRINT USING "#.######"` shows six decimals.
- `STR$` puts a space before every number, even a negative one: `STR$(2)`
  is `" 2"`. There's no `LTRIM$`, so the programs drop the space with
  `MID$(STR$(N), 2)`.
- A `FOR` loop with nothing to count still runs once: `FOR E = 1 TO 0`
  runs its body with `E` = 1. Where a range can be empty, the programs use
  `WHILE` instead.
- `FOR` and `NEXT` can't share a line: `FOR J = 1 TO 3 : NEXT J` stops with
  "FOR without NEXT".
- bwbasic can't read command-line arguments, so the run script passes the
  data path in the `DATA` environment variable, read with `ENVIRON$`.
  `OPEN "I", #1, ENVIRON$("DATA")` fails to parse, so the programs copy it
  into `F$` first.
- An `IF` inside another `IF`'s `THEN` ignores its own condition:
  `IF A = 1 THEN IF B = 0 THEN PRINT "yes" ELSE PRINT "no"` prints "yes"
  when `B` is 5. The programs join conditions with `AND` instead.
- An array element used inside a 2-D subscript can read the wrong cell:
  with `FEAT(3) = 2`, `X(1, FEAT(3))` gave `X(3, 2)`. Copying `FEAT(3)`
  into a plain variable first gives the right one.
- A misspelled statement isn't an error. bwbasic stops at the line and
  hands it and every line after it to the shell, so `PRNT "b"` prints
  "PRNT: not found".
- An error prints a message and drops to the `bwBASIC:` prompt, yet the
  interpreter still exits with status 0. The run script watches the output
  for `ERROR` or the prompt and fails the run instead.
