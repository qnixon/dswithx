Each seed is a hash reference, a small record read as `$seed->{len}`, and
`map` pairs every training seed with its distance and row number. The sort
block, `$a->{d} <=> $b->{d} || ...`, compares distances first. When they're
equal, `<=>` returns 0, which is false, so `||` falls through to the row
number and the earlier training seed wins. Perl's sort is stable anyway,
but spelling out the tie rule means the result doesn't depend on that.

A hash counts the votes: `$votes{$label}++` starts a missing key at 0 with
no warning. Perl has no kNN or distance function, so both are written out,
and `split /,/` reads the file because no field is quoted.
