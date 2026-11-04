Each part is a record with a `Boolean` label and a `Long_Float` score,
held in a `Vector`. One loop per threshold sorts every part into one of
four `Natural` counts, and a small `Ratio` function converts two counts to
`Long_Float` before dividing, since Ada never mixes the two types.

Appending a part needs `Part'(...)` around the record: in Ada 2022 a
`Vector` can be written as an aggregate too, so GNAT calls the bare form
ambiguous. The AUC loops over every defective and good pair, 33 times 167,
adding 2 for a win and 1 for a tie.
