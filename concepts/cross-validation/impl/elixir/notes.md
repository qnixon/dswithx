The kNN classifier is the same as on the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. `Enum.chunk_every` cuts the 150 training
seeds into five blocks of 30. For each fold, `Enum.at` picks the held-out
block, and `List.delete_at` drops it so `Enum.concat` can join the other
four.

The values of k come from the range `1..15//2`, where `//2` is the step.
`Enum.reduce` prints each accuracy and replaces the leader only on a
strictly larger score, so ties keep the smaller k. Elixir has no
cross-validation, and Hex packages such as Nx aren't installed.
