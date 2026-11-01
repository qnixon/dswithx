---
name: COBOL
first_appeared: 1959
paradigm: Imperative, procedural
toolchain: GnuCOBOL 3.2
image: debian:trixie-20261027-slim + gnucobol3 3.2-3
highlight: cobol
---

COBOL (COmmon Business-Oriented Language) was designed in 1959 by a
committee drawing heavily on Grace Hopper's FLOW-MATIC. It still runs a
large share of banking and government systems, and it was built for this
kind of work: reading records and doing exact decimal arithmetic. It even
has `MEAN`, `MEDIAN`, `VARIANCE`, and `STANDARD-DEVIATION` intrinsic
functions; the from-scratch versions avoid them. GnuCOBOL compiles each
program to C and builds it with gcc.

## Quirks

- Programs use fixed format: code starts in column 8, and every variable is
  declared up front in the `DATA DIVISION`.
- Numbers are fixed-point decimals described by a picture: `PIC S9(9)V9(6)`
  is signed, with nine digits before the point and six after, so there is
  no floating-point rounding.
- `FUNCTION VARIANCE` divides by n, not n − 1, so it wouldn't match the
  sample variance used here anyway.
