Each example is a hash ref, `{ x => [...], y => 0 }`, read as
`$_->{x}` and `$_->{y}`. The gradient step has no explicit loop over
students: `map` builds every error, a nested `map` passed to `sum` turns
them into one gradient entry per weight, and a third `map` replaces
`@weights` all at once, so every weight moves by the same gradient.

Perl has no regression, classifier, or matrix type, so `sigmoid`, `dot`,
and `scale` are short subs, with `exp`, `log`, and `sqrt` as the only math
built-ins. Counting correct predictions uses `grep`, which gives the
number of matches when assigned to a single value.
