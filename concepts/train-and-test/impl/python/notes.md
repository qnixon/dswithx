Each fit builds the normal equations, a small square system whose answer
is the polynomial's coefficients, and `solve` works through it by Gaussian
elimination. At each column it swaps up the row with the largest entry,
called partial pivoting, which keeps rounding error from growing.

Speeds are first mapped onto −1 to 1 using the training range only, so
powers up to the 16th stay a sensible size. Python's standard library has
`statistics.linear_regression` for a straight line, but nothing we use
here fits a polynomial; NumPy's `polyfit` would, but NumPy isn't
installed.
