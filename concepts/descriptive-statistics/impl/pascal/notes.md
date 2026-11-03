Free Pascal's Math unit has `Mean`, `Variance`, and `StdDev`, and its
`Variance` divides by n − 1 like ours, but we leave them out and write
each statistic as a loop. Sorting is a general tool, so
`TArrayHelper<Double>.Sort` from `Generics.Collections` orders the values
for the median.

Pascal declares every variable before the `begin` of its block, with its
type. `ReadColumn` grows a dynamic array one value at a time with
`SetLength`, splits each line with the string helper `Split`, and parses
it with `StrToFloat`. `/` always gives a real number and `div` is for
whole numbers, so the mean needs no conversion. `Value:0:6` prints six
decimals.
