The `statistics` module gained `linear_regression` and `correlation` in
Python 3.10, so a straight-line fit is now two calls with no imports beyond
the standard library. `linear_regression(xs, ys)` returns the slope and
intercept as a named tuple, which we unpack into two variables.

Neither function reports r squared, but for a straight line with an
intercept it's just r times r, the same shortcut the from-scratch version
uses. The order of the arguments matters: `xs` is the predictor (hours)
and `ys` is the thing being predicted (score).
