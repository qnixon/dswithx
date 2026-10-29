---
name: Ruby
first_appeared: 1995
paradigm: Object-oriented, with functional features
toolchain: CRuby 4.0.9
image: ruby:4.0.9-slim-trixie
---

<!-- Placeholder text: to be written. -->

Ruby is best known for web development with Rails, and rarely for data
science. Its blocks and rich collection methods still make numeric code read
almost like the formulas.

## Quirks

- Since Ruby 3.4, `csv` is a bundled gem rather than part of the standard
  library, so implementations here parse simple CSV files by hand.
- Integer division truncates: `7 / 2` is `3`. Convert to floats first.
