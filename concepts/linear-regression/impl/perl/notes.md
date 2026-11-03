Perl stays close to the formulas once the columns are read. `sum` comes
from List::Util, a core module, and `map` runs its block once per value,
with the value in `$_`. So the sum of squared deviations is `sum` over a
`map` that squares `$_ - $mean_x`. List::Util also has a `zip`, but the
cross-product sum simply walks the row numbers, `0 .. $#xs`, and reads
`$xs[$_]` and `$ys[$_]` together.

Perl has no regression or correlation function, so there was no built-in to
skip. There's no CSV reader either: `split /,/` breaks each line on commas,
and a hash maps each header name to its position. Returning both columns
from one sub takes array references, `\@xs` and `\@ys`.
