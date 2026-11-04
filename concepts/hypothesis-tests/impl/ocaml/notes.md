We never shuffle at random. OCaml 5.3's `Array.shuffle` would give a
random relabeling, but a sample only estimates the p-value, and with 8
plants in each group we can try all 12,870 splits. The recursive
`each_chosen_total` walks the plants in order, either choosing each one or
skipping it, and calls a function with every finished total.

Two `ref` cells count the splits and the extreme ones. The totals are
`int`, so `abs difference >= abs observed` compares whole numbers, and the
6 exact ties all count.
