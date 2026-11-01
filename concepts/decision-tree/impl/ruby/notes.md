Each kind of node is its own class, made with `Data.define`: `Leaf` holds a
label, and `Split` holds a feature, a threshold, and two children. Data
objects are frozen and have no setters, so `leaf.label = "no"` raises
`NoMethodError`, which suits a tree that never changes once grown. `predict`
and the printing loop use `case`/`in` to match on the class and pull out the
fields in one step. If no pattern matched, Ruby would raise
`NoMatchingPatternError` rather than return `nil`. The candidate thresholds
come from `uniq.sort.each_cons(2)`, which yields each pair of neighboring
values. Neither the standard library nor the bundled gems include a decision
tree, so there was no built-in to skip.
