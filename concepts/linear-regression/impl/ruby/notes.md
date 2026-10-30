Ruby reads almost like the math. `sum` takes a block, so
`xs.sum { |x| (x - mean_x)**2 }` is the sum of squared deviations in one
expression, and `xs.zip(ys).sum { |x, y| ... }` pairs the two columns and
unpacks each pair for the cross-products. A hash keeps the four results in
insertion order, so printing them is one loop.

Ruby's standard library has no regression or correlation function, so there
was no built-in to skip. The awkward part is reading the file. `csv` is a
bundled gem rather than part of the standard library, so `read_columns`
splits each line on commas by hand and finds each column with
`header.index`. That works for this file but would break on quoted fields.
