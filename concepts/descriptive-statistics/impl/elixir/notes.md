Elixir never changes data in place. Each step takes a list and returns a
new value, and the pipe, `|>`, passes a value into the next function as its
first argument, so reading the file reads top to bottom.

Elixir does have `Enum.sum`, a general tool, but no mean, median, or
variance, so those are written out. `Enum.sort` orders the values, `/`
always gives a float, and `div` is integer division, which the median uses
to find the middle. `[header | rows] = ...` splits off the first line by
pattern matching. The square root comes from Erlang, whose libraries
Elixir calls directly: `:math.sqrt`.
