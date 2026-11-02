Swift has no mean, median, or variance, so we write them with
`reduce(0, +)` for the sums and `sorted()` for the median. Foundation,
which ships with Swift, reads the file and formats six decimals with
`String(format:)`.

Swift is strict about types. It never mixes `Int` and `Double` on its own,
so `sum / n` won't compile until `Double(n)` converts the count. Missing
values are spelled out, too: `Double("28.6")` returns an optional that
might be `nil`, and the `!` says we're sure it isn't, stopping the
program if we're wrong. A function that can fail says `throws`, and each
call says `try`.
