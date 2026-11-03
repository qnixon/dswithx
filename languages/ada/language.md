---
name: Ada
first_appeared: 1980
paradigm: Imperative, structured, strongly typed
toolchain: GNAT 14.2
image: debian:trixie-20261027-slim + gnat-14 14.2.0-19
highlight: ada
---

Ada was designed for the United States Department of Defense by a team led
by Jean Ichbiah, and its first reference manual appeared in 1980. It's
named after Ada Lovelace, who wrote what is often called the first
computer program. Ada was built for large programs that must not fail,
and it still flies in aircraft, runs railway signals, and guides air
traffic control. GNAT, the compiler used here, is part of GCC.

Ada spells things out. Blocks end with `end if`, `end loop`, and
`end Main`, and every value has a type that the compiler checks strictly.
It won't mix integers and floats, or even two integer types, without a
conversion. Arrays can be indexed from any range you choose, and they
carry their bounds with them as `A'First` and `A'Last`. Containers and
sorting are generics: you make a copy for your own types with `is new`.
Crates from Alire, Ada's package manager, aren't installed here. The run
script turns on most of GNAT's warnings with `-gnatwa` and makes each one
an error.

## Quirks

- `X / Y` with an Integer `X` and a Float `Y` doesn't compile ("invalid
  operand types for operator"). You convert first: `Float (X) / Y`.
- Integer `/` rounds toward zero, so `(-7) / 2` is −3. Ada has both `mod`
  and `rem`, which differ on negative numbers: `(-7) mod 3` is 2, and
  `(-7) rem 3` is −1.
- Write `(-7) / 2`, not `-7 / 2`: GNAT warns that the unary minus should be
  parenthesized, and here that warning stops the build.
- Integer overflow is checked. Adding 1 past `Integer'Last` raises
  `CONSTRAINT_ERROR : overflow check failed` instead of wrapping around.
- `Integer'Image (5)` is `" 5"`, with a space where a minus sign would go.
  `Long_Float'Image (2.0 / 3.0)` gives ` 6.66666666666667E-01`, so the
  programs print with `Put` and `Exp => 0` instead.
- An array literal is written with square brackets, `[3, 1, 2]`. The older
  round brackets still work, but GNAT warns that they're obsolescent.
- `Ada.Text_IO` and `Ada.Strings.Fixed` both have a `Count`, so with both
  in `use`, a bare `Count (Line, ",")` doesn't compile until you name the
  package: `Ada.Strings.Fixed.Count`.
- An enumeration value prints in capitals: with `type Feature is
  (Has_Link, Known_Sender)`, `Feature'Image (Has_Link)` is `"HAS_LINK"`.
