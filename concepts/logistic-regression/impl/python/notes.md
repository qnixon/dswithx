Python's standard library has `statistics.linear_regression` but nothing for
logistic regression, and scikit-learn's `LogisticRegression` isn't
installed, so there was no built-in to skip. Each step of gradient descent
is two list comprehensions: one for every student's error, `p - y`, and one
that averages those errors times each input. Building a new `weights` list
from the old one means every weight updates from the same gradient.

`math.exp` raises an `OverflowError` above about 709, so `sigmoid` would
fail for a score below −709. Scores here stay between −3.4 and 4.4, but
production code guards against it.
