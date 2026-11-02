Training is counting into hash tables. The value counts are keyed by a list
such as `("has_link" "yes" "spam")`, which needs `:test 'equal`: the default
test, `eql`, treats two equal lists or strings as different keys, so every
lookup would miss. `(gethash key table 0)` gives 0 for a key never seen.

Watch the division. `(/ 55 150)` is the exact fraction `11/30`, and its log
comes out a single float, so `divide` converts the counts to doubles first.
For the tie rule, we sort the labels with `string<` and keep the first
unless a later label scores strictly higher. Common Lisp has no naive Bayes
or probability functions to skip.
