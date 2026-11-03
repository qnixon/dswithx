---
name: PHP
first_appeared: 1995
paradigm: Imperative, scripting, object-oriented
toolchain: PHP 8.4.24
image: debian:trixie-20261027-slim + php8.4-cli 8.4.24-1~deb13u1
highlight: php
---

PHP was released in 1995 by Rasmus Lerdorf as "Personal Home Page Tools," a
set of scripts for tracking visits to his online résumé. It grew into a
language for building web pages on the server, and it now runs WordPress,
Wikipedia's MediaWiki, and a large share of the web. The name now stands
for "PHP: Hypertext Preprocessor."

A PHP file starts with `<?php`, and every variable name starts with `$`.
PHP's main collection type is the array, which is an ordered map: with keys
0, 1, 2, and so on it acts as a list, and with string keys it acts as a
dictionary. The standard library is large and built in, from `array_sum`
and `usort` to `str_getcsv`. Packages from Composer, PHP's package manager,
aren't installed here. Every program here starts with
`declare(strict_types=1)`, and the run script fails the run on any warning
or deprecation notice.

## Quirks

- `/` gives a whole number only when the division is exact: `10 / 2` is the
  integer 5, while `10 / 3` is 3.3333333333333335. `intdiv(-7, 2)` is −3,
  and `-7 % 3` is −1.
- `sort` compares numeric strings as numbers, so `"10"`, `"9"`, and `"1"`
  sort to 1, 9, 10. Add a string such as `"abc"` and it goes last.
- `==` converts numeric strings: `"1" == "01"` and `"10" == "1e1"` are both
  true. `===` compares without converting.
- The strings `"0"` and `""` are false, but `"0.0"`, `"00"`, and `" "` are
  true.
- Array keys are converted: `$h["1"]` and `$h[1]` are the same entry, and a
  float key such as 1.5 is cut to 1, with a deprecation notice.
- `sort` throws away the keys and numbers the values from 0 again.
- `"5 apples" + 2` is 7, with a warning.
- `max([])` stops the program with a `ValueError`, while
  `array_sum([])` is 0.
- An integer that overflows becomes a float: `PHP_INT_MAX + 1` is
  `9.223372036854776E+18`.
- `round(2.5)` is 3 and `round(-2.5)` is −3: halves round away from zero.
- `str_getcsv` raises a deprecation notice in PHP 8.4 unless you pass its
  `escape` argument, because its default is going to change.
