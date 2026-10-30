---
name: COBOL
first_appeared: 1959
paradigm: Imperative, procedural
toolchain: GnuCOBOL 3.2
image: debian:trixie-20261027-slim + gnucobol3 3.2-3
highlight: cobol
---

<!-- Placeholder text: to be written. -->

COBOL (COmmon Business-Oriented Language) was designed in 1959 by a
committee drawing heavily on Grace Hopper's FLOW-MATIC. It still runs a large
share of the world's banking and government systems, and it was built for
exactly this kind of work: reading records and doing exact decimal arithmetic.

## Quirks

- Programs are written in fixed format: code starts in column 8, and
  everything is declared up front in the DATA DIVISION.
- Numbers are fixed-point decimals described by a picture: `PIC S9(9)V9(6)`
  is a signed number with nine digits before the decimal point and six after,
  so no floating-point rounding surprises.
- Since 1989, COBOL has had intrinsic functions for MEAN, MEDIAN, VARIANCE,
  and STANDARD-DEVIATION; from-scratch versions avoid them.
