`glm()` fits generalized linear models, and `family = binomial` makes it a
logistic regression. It doesn't take 1,000 small gradient steps. It uses
iteratively reweighted least squares, which solves a weighted regression
again and again, and here it settles in five rounds on the same weights,
to six decimals, as the from-scratch version.

`scale()` standardizes the training columns and remembers each mean and
standard deviation, so the test rows are scaled with the training ones.
`fitted()` gives each training student's probability for the log-loss, and
`plogis()`, R's logistic function, turns the test rows' weighted sums into
probabilities.
