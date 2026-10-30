<!-- Placeholder text: to be written. -->

**Easy:** `Hash.new(0)` gives a counter whose missing keys read as zero, and
arrays work as hash keys, so `[feature, value, label]` indexes the counts
directly. `tally` counts labels and `fdiv` avoids integer division.

**Hard:** integer division truncates, so every probability needs `fdiv` (or a
`to_f`); forgetting one would silently give `0` and `Math.log(0)` of
`-Infinity`. Methods cannot see local variables, so the scorer is a lambda
closing over the counts.
