C is the language most of the others are written in, and you can see how
much they do for you. There's no array that grows on its own, so
`read_column` starts with room for 64 values and doubles it with `realloc`
whenever it fills. There's no CSV reader, so `strtok` cuts each line at
its commas, and `strtod` turns the text into a `double`.

Sorting is the one thing provided: `qsort` sorts any array, given the
element size and a comparison function that receives untyped pointers.
C has no `mean` or variance functions to avoid, so the statistics are
plain loops.
