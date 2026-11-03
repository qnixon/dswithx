---
name: Perl
first_appeared: 1987
paradigm: Imperative, scripting
toolchain: Perl 5.40.1
image: debian:trixie-20261027-slim + perl 5.40.1-6+deb13u1
highlight: perl
---

Perl was created in 1987 by Larry Wall, a linguist working as a programmer,
to pull reports out of text files more easily than shell scripts and awk
allowed. Its regular expressions became the model most other languages
copied, and in the 1990s it ran much of the early web, along with a great
deal of system administration and, for a while, the Human Genome Project's
data processing. Its motto is "There's more than one way to do it."

Every variable name starts with a sigil that says what it holds: `$` a
single value, `@` an array, and `%` a hash, Perl's dictionary. The same
array can be read in different contexts, so `@values` gives the list, while
`my $n = @values` gives its length. Perl ships with a set of core modules,
such as List::Util for `sum`, `min`, and `max`. Modules from CPAN, Perl's
package archive, aren't installed here. Every program starts with
`use strict` and `use warnings`, and the run script fails the run if Perl
prints any warning.

## Quirks

- A plain `sort` compares text, so `sort (10, 9)` gives 10, 9. Numbers
  need `sort { $a <=> $b }`.
- Numbers and strings have separate operators: `==` and `<` compare
  numbers, while `eq` and `lt` compare text. `"10" == 10.0` is true, but
  `"10" eq "10.0"` is false.
- The strings `"0"` and `""` are false, but `"0.0"`, `"00"`, and `" "` are
  true.
- `/` always divides exactly, so `-7 / 2` is −3.5. `int` drops the fraction,
  giving −3, while `%` takes the sign of the right side: `-7 % 3` is 2.
- `"3 apples" + 2` is 5, with only a warning.
- `split /,/` drops empty fields at the end, so `"1,2,,4,,"` splits into
  four fields. A limit of −1 keeps all six.
- Hash order changes from run to run: the same seven keys came out as
  `cbegadf` one time and `bcegafd` the next.
- Reading past the end of an array or a missing hash key gives `undef`,
  not an error.
- An integer too big for 64 bits quietly becomes a float:
  `18446744073709551615 + 1` prints `1.84467440737096e+19`.
