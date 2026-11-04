Each row of the augmented matrix is an array ref, so the pivot swap is one
slice assignment: `@m[$col, $pivot]` takes `@m[$pivot, $col]`, which trades two
refs without copying a number. The rest are loops written with statement
modifiers, such as `... for $col .. $n`.

`solve` names its arguments `$lhs` and `$rhs`, because `$a` and `$b` are
the variables `sort` uses.
PDL and Math::Matrix would solve the system, but neither is installed.
