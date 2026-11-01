Python's standard library has no decision tree, and scikit-learn's
`DecisionTreeClassifier` isn't installed, so there was no built-in to skip.
The tree is plain data: a leaf is the string `"yes"` or `"no"`, and a split
is a tuple `(feature, threshold, left, right)`. `predict` walks down until
`isinstance(node, tuple)` is false, and `grow` calls itself on each side,
which is the recursion the method describes.

The search is brute force. At the root it tries 228 thresholds (61 for
humidity, 129 for pressure, and 38 for wind), rebuilding both sides for
each one. With 150 days that still takes a fraction of a second.
