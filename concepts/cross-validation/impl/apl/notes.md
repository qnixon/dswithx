The classifier is the one from the k-nearest neighbors page, and each fold
is a mask. `⌈(⍳N)÷SIZE` gives every training row its fold number, 1 1 … 5 5,
so `HELD←FOLD=F` marks fold F, `HELD⌿TP` keeps its rows, and `~HELD` keeps
the other four folds. `CV¨KS` scores all eight values of k with one each.

One surprise: `CLASSIFY` never receives the reference seeds. APL names are
dynamically scoped, so it reads `RP`, `RL`, and `K` from the locals of
`CORRECT`, which called it. `⍳` finds the first top accuracy, so a tie goes
to the smaller k. There is no cross-validation built-in to avoid.
