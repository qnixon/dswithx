---
name: Julia
first_appeared: 2012
paradigm: Multi-paradigm (multiple dispatch, functional, imperative)
toolchain: Julia 1.13.3
image: julia:1.13.3-trixie
highlight: julia
---

Julia was designed for scientific computing, to be easy to write and fast
to run: it compiles each function the first time it's called. Its data science
tools, such as DataFrames.jl, CSV.jl, and GLM.jl, are packages installed
with Julia's package manager, Pkg. None is installed here, and the tests run
without a network, so only Base and the standard library are available.
That library already covers a lot: the backslash operator solves least
squares, and `Statistics` has `mean`, `median`, `var`,
`std`, and `cor`. The from-scratch versions skip them so the arithmetic
stays visible.

## Quirks

- A dot applies an operation to every element: `x .- 1` subtracts 1 from
  each value, and `sigmoid.(z)` calls `sigmoid` on each one. Plain
  `x - 1` is a `MethodError`.
- Arrays are indexed from 1, as in R.
- `/` always gives a float, so `7 / 2` is `3.5`; `÷` is integer division.
- `exp` of a square matrix is the matrix exponential, not `exp` of each
  element; that needs `exp.(M)`.
- The standard library has no CSV parser, so implementations here split
  each line on commas.
