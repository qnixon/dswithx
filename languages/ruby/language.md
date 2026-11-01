---
name: Ruby
first_appeared: 1995
paradigm: Object-oriented, with functional features
toolchain: CRuby 4.0.9
image: ruby:4.0.9-slim-trixie
highlight: ruby
---

Ruby is best known for web development with Rails and rarely shows up in
data science, but its blocks and collection methods make numeric code read
almost like the formulas: `values.sum`, `labels.tally`, and `sort_by` do a
lot of the work. Ruby has no statistics in its standard library, so nothing
needs avoiding. The only thing we leave out is the `csv` library: since
Ruby 3.4 it's a bundled gem, installed alongside Ruby but no longer part of
the standard library. The implementations split each line on commas
instead.

## Quirks

- Integer division truncates: `7 / 2` is `3`. Use `fdiv` or convert to a
  float first.
- `tally` counts each distinct value in one call:
  `[1, 2, 2, 3].tally` is `{1 => 1, 2 => 2, 3 => 1}`.
- `sort_by` isn't guaranteed to be stable, so code that needs ties in file
  order adds the position to the sort key.
