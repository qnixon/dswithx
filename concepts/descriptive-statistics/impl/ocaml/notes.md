OCaml checks types before the program runs, and it never mixes integers
and floats. Floats get their own operators, `+.`, `-.`, and `/.`, so
dividing the total by the count takes `float_of_int n` first. Writing
`total / n` won't compile.

OCaml's standard library has no mean, median, or variance, so each is
written out. `Array.fold_left` adds the values up, and sorting is a
general tool: `Array.sort compare` orders them in place. Reading the file
takes `In_channel.input_lines`, `String.split_on_char` cuts each line at
its commas, and `List.find_index` returns `Some` position, or `None` when
the column is missing, which the `match` must handle.
