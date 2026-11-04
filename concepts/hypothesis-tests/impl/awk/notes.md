We never shuffle at random. A recursive function, `choose`, walks every way
to pick 8 of the 16 plants, carrying a running total, and counts all 12,870
splits. awk has no local variables except extra parameters, so the loop
counter `i` sits after the real ones. Leave it out and every call shares one
`i`: on this data the run then reports 9 splits instead of 12,870.

Every awk number is a double, but whole numbers this size are exact, so the
totals compare without near-ties. mawk has no bit operations, since
`and(5, 3)` is an undefined function, so the splits come from recursion.
