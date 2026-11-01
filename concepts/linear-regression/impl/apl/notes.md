Each sum is a whole-array expression: `DX×DY` multiplies the deviations pair
by pair, and `+/` adds them up, so the cross-product sum is `+/DX×DY` with no
loop. The slope, intercept, and correlation follow directly from those
three sums.

APL does have a built-in that would do all of this: `⌹` (matrix divide)
solves least squares, and `Y⌹1,[1.5]X` returns the intercept and slope in
one step. We checked that it gives the same 42.225716 and 5.202961, and then
left it out, because it performs the method itself. `*0.5`, a power, is the
square root.
