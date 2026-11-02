We count by turning each training row into keys and tallying them with
`countAll`: `sort` brings equal keys together, `group` gathers each run,
and the run's length is the count. Value counts are keyed by a
`(feature, value, label)` triple, and each row is itself a list of
(column, value) pairs. `base` has no map type, so all of these are
association lists searched with `lookup`, which returns a `Maybe`.

The tie rule needs care. `maximumBy` returns the last of equal scores, so
`classify` uses `minimumBy` with `Down`, which flips the order and keeps
the first. The labels come out of `sort`, so a tie goes to the
alphabetically first one.
