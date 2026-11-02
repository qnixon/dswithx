Octave works on whole arrays, so most lines here are one formula. `sum`
adds every value, and `(values - mean_value) .^ 2` squares every
difference at once. The dot matters: `.^` squares each element, while `^`
alone would ask for a matrix power.

Octave ships `mean`, `median`, `var`, and `std`, which would do this whole
page in four calls, so we write each one out instead. There's no CSV
reader that looks up a column by name either: `read_column` splits the
file with `strsplit` and finds the header with `strcmp`. Arrays count from
1, so the middle pair of 120 values is at positions 60 and 61.
