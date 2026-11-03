Each student is a record holding a fixed-size `TVector` of three inputs,
the first always 1 so that weight 0 acts as the intercept, plus the label.
`ReadRows` finds the columns by name and appends each row to a training or
test dynamic array, grown with `SetLength`. We leave out the Math unit's
`Mean` and `StdDev`, so the scaling is written as loops.

Every step sums the whole gradient in a nested loop over students and
weights, then moves all three weights at once. `Ord` turns the Boolean
`p >= 0.5` into 0 or 1 to compare with the label, and the accuracy needs
no cast, since `/` always gives a real number.
