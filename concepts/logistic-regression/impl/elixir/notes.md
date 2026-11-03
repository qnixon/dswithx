The weights are a list, and no step changes it. `step` works out every
error from the old weights first, then `Enum.zip_with` pairs each weight
with its column of inputs to build a new list, so every weight moves from
the same gradient. `Enum.reduce` over the range `1..1000` threads the
weights through the steps and hands back the last list.

Elixir has no matrix module (`Matrix` isn't defined) and no `Enum.mean`,
so `sigmoid`, `dot`, `mean`, and `sd` are short functions, with `exp` and
`log` from Erlang's `:math`. Watch `Enum.zip_reduce`, which `dot` uses:
given lists of different lengths, it quietly stops at the shorter one
instead of raising. `Enum.split_with` divides the training and test rows
in one pass.
