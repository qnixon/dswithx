---
name: Octave
first_appeared: 1988
paradigm: Array-oriented, imperative, dynamically typed
toolchain: GNU Octave 9.4
image: debian:trixie-20261027-slim + octave 9.4.0-1
highlight: matlab
---

GNU Octave is a free language for numerical computing, written to run
MATLAB programs with few or no changes. Work on it began in 1988, as companion
software for a chemical engineering textbook, and the first public release
came in 1993. Like MATLAB, it's still used in engineering and signal processing
courses.

Every value is an array, and arithmetic works on whole arrays at once:
`values - m` subtracts from every element, and `A * v` is a matrix product.
Octave also ships many of the methods themselves, such as `mean`, `var`,
`polyfit`, and `eig`. The from-scratch versions here write those out. The
Octave Forge packages, such as statistics with its `kmeans`, aren't
installed.

## Quirks

- `*` and `^` are matrix operations. `[1 2 3] .^ 2` squares each element and
  gives `1 4 9`; `[1 2 3] ^ 2` is an error, because only a square matrix has
  a power.
- Arrays count from 1, and `v(end)` is the last element. `v(0)` is an error.
- Dividing integers rounds to the nearest whole number: `int32(7) / 2` is 4,
  and `int32(-7) / 2` is −4. `idivide` truncates instead, giving 3.
- A line without a semicolon prints its result, so `x = 5` shows `x = 5`.
  Every line here ends with a semicolon unless it prints on purpose.
