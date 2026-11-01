---
name: awk
first_appeared: 1977
paradigm: Data-driven, pattern–action
toolchain: mawk 1.3.4
image: debian:trixie-20261027-slim
highlight: awk
---

awk was written at Bell Labs in 1977 by Alfred Aho, Peter Weinberger, and
Brian Kernighan, for processing text files one line at a time. It splits
each line into fields for you, so a CSV with no quoted fields is natural
input, and every number is a float. That makes it a surprisingly capable
data tool, as long as you're happy to build everything else yourself. These
implementations run on mawk, the awk that comes with Debian, and stick to
features defined by POSIX.

## Quirks

- POSIX awk has no sort function, and mawk has no `asort`, so sorting is
  written by hand.
- Arrays are associative, indexed by strings, and an unset variable is both
  `0` and the empty string.
- `7 / 2` is `3.5`: there is no integer division.
