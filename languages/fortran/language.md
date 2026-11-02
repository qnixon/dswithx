---
name: Fortran
first_appeared: 1957
paradigm: Imperative, procedural, array-oriented
toolchain: GNU Fortran 14.2
image: debian:trixie-20261027-slim + gfortran-14 14.2.0-19
highlight: fortran-free-form
---

Fortran (FORmula TRANslation) came out of IBM in 1957, and it is the
oldest language on this site. It was built for numerical work and is
still used for it, in weather and physics simulations, and in LAPACK, the
linear-algebra library that NumPy and R build on. Here it is compiled with
gfortran using the 2018 standard.

Modern Fortran works on whole arrays at once: `x - mean` subtracts from
every element, and `sum`, `minloc`, `dot_product`, and `matmul` are
built-in intrinsics. What it lacks is everything outside the numbers. There
is no sort, no CSV reader, and no string splitting, so the implementations
write their own. LAPACK itself is a separate library and isn't installed
here.

## Quirks

- Without `implicit none`, a variable whose name starts with i through n is
  silently an integer: `index_var = 2.9` stores 2. Every program here starts
  with `implicit none`, which makes an undeclared name a compile error.
- Arrays count from 1, and 2-D arrays are stored column by column.
- `7 / 2` is integer division, giving 3; `7.0 / 2` gives 3.5.
- The `f0.6` format drops the zero before the point, printing 0.5 as
  `.500000`, so a small `say` helper puts it back.
