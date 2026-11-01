Each step makes two passes. The first goes over the 150 training rows and
adds every row's error times its inputs into a fresh `gradient` slice; the
second moves the weights. Updating `weights` in place is safe only because
the whole gradient exists first. Move the update into the row loop and it
becomes stochastic gradient descent, which gives an intercept of 0.758788
instead of 0.753594 and fails the test.

The training loop is `for range steps`, since Go can range over an integer.
Test rows go through the same `scale` closure, so they use the training mean
and standard deviation. The standard library has no logistic regression, so
there was no built-in to skip.
