A `Key` record with `feature`, `value`, and `label` fields keys the counts.
Records get `equals` and `hashCode` from their fields, so two `Key`s built
from the same three strings find the same `HashMap` entry; a plain class
would count them apart. `merge(key, 1, Integer::sum)` adds one, and
`getOrDefault` reads a missing count as 0, where `get` would return `null`.
The label counts live in a `TreeMap`, which keeps its keys sorted, so the
labels are tried alphabetically and only a strictly higher score wins a tie.
Every count is an `int`, and `55 / 150` is 0, so each division casts to
`double` first. No naive Bayes library is involved, and Java ships none.
