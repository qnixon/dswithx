A recursive proc, `choose`, walks the plants in order. At each plant it
calls itself twice: once taking the plant into the compost group and once
skipping it. When it has taken 8, it counts the split, so every one of the
12,870 splits is reached once. The counters are `global`, since a Tcl proc
sees only its own variables otherwise.

The totals are whole numbers, so `>=` never meets a floating-point
near-tie. In `expr`, `/` between two integers rounds down, so the means
use `double()` first. Tcllib, which has a statistics package, isn't
installed.
