<!-- Placeholder text: to be written. -->

**Easy:** `sum` takes a block, so the variance is one line, and
`File.readlines(path, chomp: true)` with destructuring splits off the header.

**Hard:** reading the CSV. The `csv` library stopped being part of the
standard library in Ruby 3.4 (it is now a bundled gem), so this version splits
lines on commas by hand. That works for this simple file but would break on
quoted fields.
