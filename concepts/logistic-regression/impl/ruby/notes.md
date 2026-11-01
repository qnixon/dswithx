Ruby keeps each step of gradient descent to one line. `transpose` turns the
training rows into one array per feature, so the means and standard
deviations are a `map` over columns. Inside the loop, `errors.zip(xs).sum`
with a block is the sum of error times input for one weight, and building
the new `weights` array from the old one means every weight updates from the
same gradient.

The scaling is a lambda, `scale`, called as `scale.(x)`, so the test rows
reuse the training means and standard deviations. Ruby's standard library
has no regression or classifier, so there was no built-in to skip.
