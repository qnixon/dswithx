Each row becomes a named tuple of a `Bool` and a `Double`, so we skip
declaring a struct. `report` switches on the pair `(flagged, defective)`,
and the compiler checks that the four cases cover every combination, one
per cell of the confusion matrix.

Swift won't multiply or divide an `Int` by a `Double`: `a * b` with one of
each is a compile error, so every count goes through `Double(_:)` before a
ratio. For the AUC, `filter` and `map` pull out the defective and good
scores, and two nested loops compare every pair, 2 points for a win and 1
for a tie, as a whole-number `Int` until the last division.
