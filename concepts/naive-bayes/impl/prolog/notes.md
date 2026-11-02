We turn every CSV value into a fact, such as `cell(1, "label", "spam")`,
and keep no tables of counts. Each count is a question asked of the facts:
`aggregate_all(count, Goal, N)` counts how many ways `Goal` can succeed,
so the feature, value, and label are just its arguments. We recount every
time we score.

`sort` drops repeats, which is what counting a feature's distinct values
needs. For the tie rule, `aggregate_all(max(Score, Label), ...)` keeps the
first of equal scores, and the labels arrive in alphabetical order.
Taking `max_member` of `Score-Label` pairs would break a tie by comparing
the labels, so `"spam"` would win it. There's no
naive Bayes built in to skip.
