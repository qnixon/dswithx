<!-- Placeholder text: to be written. -->

**Easy:** the formulas map almost one to one. `sum` takes a block, and
`xs.zip(ys).sum { |x, y| ... }` destructures each pair, so the cross-product
sum reads like the math.

**Hard:** nothing about the math. Reading two columns by header name still
means splitting the CSV by hand, since `csv` is a bundled gem rather than
standard library from Ruby 3.4 on.
