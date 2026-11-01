Fixed-size arrays let the compiler check the shapes. A raw row is
`[f64; 2]`, a scaled row with its leading 1 is `[f64; 3]`, and `dot` takes
only the second, so forgetting to scale a test row before predicting is a
type error: "expected an array with a size of 3, found one with a size of
2". `[0, 1].map(...)` builds the means and standard deviations as arrays of
the same kind.

One precedence trap sits in `sigmoid`: `-z.exp()` means `-(z.exp())`, so
for `z = 2` it gives -7.389056 instead of 0.135335. We write `(-z).exp()`.
The standard library has no logistic regression, so there was no built-in
to skip.
