A matrix is a list of row lists. Elixir won't index a list with
`m[i][j]`; it raises an `ArgumentError` that points you to `Enum`, so
`mat_vec` maps each row to its dot product with the vector, and `columns`
turns rows into columns with `Enum.zip_with(rows, & &1)`. Power iteration
is `Enum.reduce` over `1..1000`, which passes each new, normalized vector
into the next step, with nothing updated in place.

Neither Elixir nor Erlang ships a matrix type or an eigenvalue routine.
Nx, the usual numerical library, is a Hex package, and it isn't installed,
so the correlation matrix, deflation, and every product are written out.
