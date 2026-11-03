Elixir's standard library has no decision tree, and no Hex package is
installed, so we write out the split search, the growing, and the
predicting. The tree is a tagged tuple, `{:leaf, "yes"}` or
`{:split, feature, threshold, left, right}`, and `grow` calls itself on
each side. `predict` and `preorder` have one function clause per shape.
Leave one out and Elixir compiles without a warning, then raises a
`FunctionClauseError` when it meets that shape. A `for` comprehension
lists every feature and midpoint, and `Enum.min_by` keeps the first of
equal scores, so the first split tried wins ties. The purity test is
`impurity == 0`, since matching the pattern `0.0` draws a warning in
OTP 27, which fails the build here.
