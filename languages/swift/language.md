---
name: Swift
first_appeared: 2014
paradigm: Multi-paradigm, compiled, statically typed
toolchain: Swift 6.0.3
image: debian:trixie-20261027-slim + swiftlang 6.0.3-2
highlight: swift
---

Apple introduced Swift in 2014 as the successor to Objective-C, and it's
now the main language for apps on the iPhone, iPad, and Mac. It's open
source and runs on Linux too, which is how it runs here. It aims to be safe
by default: values can't be missing unless their type says so, integer
overflow stops the program instead of wrapping, and arrays are copied, not
shared.

The implementations use Swift's standard library plus Foundation, which
ships with the compiler and is how Swift reads files and formats numbers on
every platform. Neither has statistics or matrices. Packages from the Swift
Package Manager, such as Swift Numerics, aren't installed. The compiler
treats every warning as an error.

## Quirks

- `Int` and `Double` never mix on their own: `1.5 / n` with an `Int` `n` is
  a compile error, so you write `1.5 / Double(n)`.
- Integer overflow crashes the program. `&+` wraps on purpose:
  `Int.max &+ 1` is −9223372036854775808.
- You can't index a string by number: `s[0]` won't compile. `"café".count`
  is 4 characters, while `"café".utf8.count` is 5 bytes.
- Arrays are values. After `var b = a` and `b[0] = 99`, `a` is unchanged.
- `-7 / 2` is −3, rounding toward zero.
