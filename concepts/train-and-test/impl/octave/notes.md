Octave can fit each curve in one call: `polyfit(x, y, d)` returns the
coefficients, and the backslash solve `A \ b` would answer the normal
equations directly. We skip both and write the elimination out in `solve`.

Octave still keeps the rest short. `z .^ (0:degree)` broadcasts a column of
scaled speeds against a row of powers, so it builds every row of
1, z, z², and so on at once, and `P' * P` and `P' * y` are the normal
equations. Swapping two rows is one indexed assignment:
`M([col, pivot], :)` on the left takes `M([pivot, col], :)`. To find the
pivot, `max` returns the position of the largest entry along with its value.
