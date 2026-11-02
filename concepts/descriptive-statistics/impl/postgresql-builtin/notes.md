Every statistic here is one of PostgreSQL's aggregate functions, so a single
`SELECT` over the table computes them all in one pass. `avg`, `var_samp`,
and `stddev_samp` are the sample versions (`var_pop` and `stddev_pop`
divide by n instead).

The median is the odd one out. There's no `median` function; instead you
ask for the 50th percentile with `percentile_cont(0.5) WITHIN GROUP (ORDER
BY minutes)`. The `cont` means continuous: with an even number of rows it
interpolates between the two middle values, which is the usual median. Its
sibling `percentile_disc` would return one of them instead.
