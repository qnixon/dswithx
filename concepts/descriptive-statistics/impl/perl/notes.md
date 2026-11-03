Perl marks every name with a sigil: `@values` is the array of commute
times, `$values[0]` is one of them, and `$n = @values` gives the count,
because an array used as a single value is its length.

Perl has no mean, median, or variance, so each is written out. `sum` comes
from List::Util, a core module that ships with Perl. Sorting is a general
tool, but watch the block: a plain `sort` compares text, putting 10 before
9, so `sort { $a <=> $b }` compares numbers. There's no CSV reader, so
`split /,/` breaks each line on commas.
