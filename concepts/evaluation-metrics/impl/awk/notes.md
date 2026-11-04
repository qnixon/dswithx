We store every row in two arrays and keep each score as whole
thousandths: `0.174` becomes 174, rounded with `int(x * 1000 + 0.5)`. The
thresholds become 500 and 300, so every comparison is between whole
numbers and tied scores stay tied.

`report` takes the suffix and threshold, and its counts and ratios are
extra parameters, the only way to get local variables in awk. The AUC
loops over every pair of parts, skips any pair that isn't one defective
and one good, and scores 2 for a win and 1 for a tie.
