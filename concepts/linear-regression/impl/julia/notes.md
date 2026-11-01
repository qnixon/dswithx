Julia can fit this line in one expression: `[ones(n) x] \ y` solves the
least-squares problem and returns the same intercept and slope, 42.225716
and 5.202961, with no `using` line needed. `Statistics` also has `cor` for
r. We skipped both so the sums stay visible.

Broadcasting keeps the sums short. `x .- mean_x` is the whole vector of
deviations, so the cross-product sum is `sum((x .- mean_x) .* (y .-
mean_y))`, close to R's version. Leave out a dot and Julia doesn't guess:
subtracting a number from a vector with plain `-` is a `MethodError`.
