PHP has no decision tree of its own, so every step is written out. A node
is a keyed array: a leaf is `['leaf' => 'yes']`, and a split holds a
feature, a threshold, and `left` and `right` subtrees. `grow` calls itself
on each side, and `predict` walks down until it reaches a key named `leaf`.

We sort each feature's values with `sort` and skip repeats by comparing
neighbors, rather than collecting them as array keys, since PHP truncates
float keys to integers. One quirk: `array_filter` keeps the original keys,
so `array_values` renumbers each side before it is grown again.
