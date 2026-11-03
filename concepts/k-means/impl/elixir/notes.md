We hold each point as a tuple, `{x, y}`, and the centroids as a list of
them. Elixir has no `while` loop, so `run` calls itself with the moved
centroids until a fresh assignment list `==` the previous one.

Elixir and Erlang ship no k-means, and Hex packages such as Nx aren't
installed. The steps use general tools: `Enum.min_by` picks the nearest
centroid and keeps the first of equal distances, so ties go to the lower
index. `Enum.sum` and `/` give each mean. A comprehension, `for {p, ^j} <- ...`,
gathers a cluster's members; the `^` pins `j` so only matching pairs pass.
Distances stay squared, which ranks centroids the same way without a square
root.
