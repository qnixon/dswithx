Ruby reads almost like the math. `values.sum { |x| (x - mean)**2 }` is the
variance's numerator in one expression, and a hash keeps the results in
insertion order, so printing them in the right order is a single loop.

The awkward part is reading the file. Since Ruby 3.4, `csv` has been a
bundled gem rather than part of the standard library, so we split each line
on commas by hand. That works for this file but would break on quoted
fields. Watch integer division too: `7 / 2` is `3` in Ruby. It's safe here
only because the values are already floats.
