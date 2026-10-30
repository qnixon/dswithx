<!-- Placeholder text: to be written. -->

**Easy:** `partition` splits train from test in one call, `tally` counts the
votes, and `max_by` picks the winner. A hash per row (`names.zip(values).to_h`)
makes reading by header name painless.

**Hard:** `sort_by` is not stable in Ruby, so neighbors at equal distance could
come back in any order. Sorting by `[distance, file_position]` restores the
file-order tie-break the concept asks for. There is no built-in Euclidean
distance like Python's `math.dist`, but it is a one-liner.
