Each seed is a PHP array with string keys, which serves as a small record,
and `array_flip` turns the header into a map from column name to position.
We sort the scored seeds with `usort` and a comparison built from `<=>`.
When two distances are equal it returns 0, and
`?:` falls through to the row number. PHP 8's sort is already stable, but
spelling out the tie rule means the result doesn't depend on that.

Votes go in an array keyed by label. PHP warns when `++` meets a missing
key, so `?? 0` supplies the first count. `array_count_values` could tally
the labels in one call, but the loop also keeps track of the leader as it
counts.
