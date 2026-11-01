JavaScript makes you write two things Python hands you. Node has no CSV
parser, so we split each line on commas and find the `minutes` column by
its place in the header. There is no `sum` either, so totals come from
`reduce((acc, x) => acc + x, 0)`.

The trap is sorting. With no comparator, `sort()` compares values as
strings, so `[11.5, 9.5].sort()` leaves 11.5 first. On this file the default
sort happens to give the right order, because every value has two digits
before the point, but we pass `(a, b) => a - b` so the median and minimum
don't depend on that. JavaScript has no statistics module, so there was no
built-in to skip.
