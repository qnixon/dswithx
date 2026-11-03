We split every line at its commas, find each column by its header name, and
read the values with `Float.parse`. Then we make the two passes the formulas
need: the means first, then the squared deviations and cross-products.

Elixir has `Enum.sum`, a general tool, but no mean, correlation, or
regression, so we write those out. To pair each `hours` value with its
`score`, `Enum.zip` turns the two lists into one list of `{x, y}` tuples,
and the function we map over it pulls both numbers apart by pattern
matching. The square root comes from Erlang's `:math.sqrt`. Hex packages
such as Nx aren't installed.
