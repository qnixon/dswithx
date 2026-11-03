---
name: Elixir
first_appeared: 2012
paradigm: Functional, concurrent
toolchain: Elixir 1.18.3
image: debian:trixie-20261027-slim + elixir 1.18.3.dfsg-1
highlight: elixir
---

Elixir was created by José Valim and first released in 2012. It runs on
the Erlang virtual machine, here Erlang/OTP 27, which Ericsson built in the 1980s for telephone
switches that had to keep running for years. Elixir gives that machine a
friendlier syntax and keeps its strengths: millions of lightweight
processes, and systems that restart the parts that fail. Discord's chat
servers and the Phoenix web framework are built on it.

Elixir is functional, and its data never changes in place. A function
takes values and returns new ones, and the pipe operator, `|>`, chains
them: `path |> File.read!() |> String.split("\n")`. Pattern matching takes
values apart, as in `[header | rows] = lines`. Elixir can call any Erlang
library directly, so the square root is `:math.sqrt`. Packages from Hex,
Elixir's package manager, aren't installed here, including Nx, its
numerical library.

## Quirks

- `/` always gives a float, so `10 / 2` is `5.0`. `div(-7, 2)` is −3,
  rounding toward zero, while `Integer.floor_div(-7, 2)` is −4.
- `1 == 1.0` is true, but `1 === 1.0` is false.
- `String.to_float("12")` raises an error because there's no decimal
  point. `Float.parse("12")` gives `{12.0, ""}`.
- `=` matches rather than assigns. `[header | rows] = lines` takes the
  first line off, and a variable can be bound again: after `x = 1` and
  `x = 2`, `x` is 2.
- `0` is true. Only `nil` and `false` are false.
- Matching the pattern `0.0` draws a warning since Erlang/OTP 27, because
  it no longer matches `-0.0`, so here it fails the run. `x == 0` compares
  by value instead: `0.0 == 0` is true.
- A function with a missing clause compiles without a warning. With no
  clause for `{:leaf, _}`, the program runs until it meets a leaf, then
  stops with a `FunctionClauseError`.
- `Enum.at([1, 2, 3], 5)` gives `nil`, not an error.
- `Enum.zip` stops at the shorter list: zipping `[1, 2, 3]` with
  `[:a, :b]` gives two pairs.
- Elixir has no `--warnings-as-errors` for scripts, so the run script fails
  the run if any warning appears, such as an unused variable.
