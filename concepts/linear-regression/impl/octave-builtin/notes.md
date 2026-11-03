`polyfit(x, y, 1)` fits a polynomial of degree 1, a straight line, by
least squares. It returns the coefficients with the highest power first,
so `p(1)` is the slope and `p(2)` the intercept. polyfit doesn't report
how well the line fits, so `corr`, Octave's correlation function, gives r,
and squaring it gives R squared.

The from-scratch version gets the same four numbers from sums of squared
deviations. Reading the CSV by column name is the same code in both.
