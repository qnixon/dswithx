Prolog states what's true rather than listing steps. `median(Sorted,
Median)` holds when `Median` is the middle of `Sorted`, and running the
program asks Prolog to find values that make `main` true. There's no
mean, median, or variance to skip, so each is a short rule, and `maplist`
applies `squared_deviation` to every value.

Two traps hide here. `D = X - Mean` doesn't subtract: it makes `D` the
term `X - Mean`, and only `is` does arithmetic. And `sort` drops repeated
values. Our 120 minutes hold just 100 distinct ones, so `sort` would get
the count, mean, and median wrong; `msort` keeps every value.
