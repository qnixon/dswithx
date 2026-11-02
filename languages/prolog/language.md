---
name: Prolog
first_appeared: 1972
paradigm: Logic programming, declarative
toolchain: SWI-Prolog 9.2.9
image: debian:trixie-20261027-slim + swi-prolog-core 9.2.9
highlight: prolog
---

Prolog (PROgrammation en LOGique) was created in Marseille in 1972 for
working with natural language, and it became the other great language of
early artificial intelligence, beside Lisp. Japan's Fifth Generation
Computer project of the 1980s was built around logic programming. Today
it's used in rule engines, type checkers, and parts of IBM's Watson.

A Prolog program is a set of facts and rules. You don't tell it what to
do next; you ask a question, and it searches for values that make the
question true, backing up to try another choice whenever a goal fails.
There are no loops and no assignment: a variable gets one value per
attempt, and repetition is recursion or helpers such as `maplist` and
`findall`. The implementations use SWI-Prolog's built-ins and the
libraries that ship with it, which have lists, strings, and sorting, but
no statistics. Add-on packs aren't installed.

## Quirks

- `X = 1 + 2` makes `X` the term `1+2`, not 3. Only `X is 1 + 2`
  evaluates.
- `sort` removes repeated values: `sort([3,1,2,1,3], S)` gives `[1,2,3]`.
  `msort` keeps them, giving `[1,1,2,3,3]`.
- A goal that can't be satisfied simply fails, with no error. If `main`
  fails, all you see is `main: false`.
- `4 / 2` is the integer 2, but `7 / 2` is 3.5. `-7 // 2` is −3, and
  `-7 div 2` is −4.
- `"rosa"` is a string and `rosa` is an atom, and they aren't equal.
- The run script stops on any warning, such as a variable used only once,
  which is usually a typo.
