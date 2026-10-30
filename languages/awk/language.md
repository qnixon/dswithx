---
name: awk
first_appeared: 1977
paradigm: Data-driven, pattern–action
toolchain: mawk 1.3.4
image: debian:trixie-20261027-slim
highlight: awk
---

<!-- Placeholder text: to be written. -->

awk was written at Bell Labs by Aho, Weinberger, and Kernighan for processing
text files line by line. It reads a CSV naturally and does floating-point
arithmetic, which makes it a surprisingly capable data tool.

## Quirks

- Implementations stick to POSIX awk, so they run on any awk (mawk, gawk,
  BusyBox, macOS).
- There is no sort function in POSIX awk; sorting is written by hand.
- Arrays are associative and 1-based by convention; uninitialized variables
  are 0 or the empty string.
