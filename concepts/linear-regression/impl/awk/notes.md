<!-- Placeholder text: to be written. -->

**Easy:** almost everything. awk splits the fields, the sums are plain loops,
and `sqrt` and `printf` are built in, so the program reads like the formulas.

**Hard:** very little. The means must be known before the deviations can be
summed, so the values are kept in two arrays and the fit happens in `END`
rather than in a single pass over the lines.
