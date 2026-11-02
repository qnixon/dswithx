`lm()` is R's general linear-model function, and this is how almost
everyone fits a line in R. The formula `score ~ hours` reads "score
explained by hours", and R adds the intercept on its own.

`lm()` does far more than this page needs. `summary(model)` reports a
standard error, a t value, and a p-value for each coefficient (the slope's
standard error here is 0.212), along with R squared. We take R squared from
it, the two coefficients from `coef()`, and r from `cor()`. Note the
awkward name `"(Intercept)"`: that's how R labels it.
