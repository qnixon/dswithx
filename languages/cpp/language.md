---
name: C++
first_appeared: 1985
paradigm: Multi-paradigm, compiled, statically typed
toolchain: GCC 14.2 (g++, C++23)
image: debian:trixie-20261027-slim + g++-14 14.2.0-19
highlight: cpp
---

Bjarne Stroustrup started C++ at Bell Labs as "C with Classes", and the
first commercial release came in 1985. It keeps C's speed and its direct
access to memory and adds classes, templates, and a large standard library
of containers and algorithms. Games, browsers, databases, and trading
systems are written in it, and so are the engines under data science
libraries such as TensorFlow, PyTorch, and XGBoost, none of which is
installed here.

The implementations use C++23, compiled with g++ with every warning an
error. The standard library brings `std::vector`, `std::map`, `std::sort`,
and `std::println`, but no statistics and no matrices, so the methods are
written out.

## Quirks

- `std::accumulate` adds in the type of its starting value: from `0` it
  sums 28.6, 43.8, and 11.5 to 82, from `0.0` to 83.9, and the compiler
  doesn't warn.
- Sizes are unsigned. On a vector of 3, `v.size() - 4` is
  18446744073709551615, not −1.
- Parentheses and braces build different vectors: `std::vector<int> a(3, 1)`
  is three 1s, but `b{3, 1}` is the two numbers 3 and 1.
- `v[5]` past the end is undefined behavior, with no check; `v.at(5)`
  checks and throws `std::out_of_range`.
- Template errors are long. Passing a whole vector to `std::println`, which
  GCC 14 can't format yet, produces 131 lines of errors.
