Every whole number from 0 to 2^16 − 1 is a mask: bit i set means plant i is
labeled compost. A `for` loop with a `where` clause keeps only the masks
whose `nonzeroBitCount` equals the group size, 12,870 of the 65,536, and a
second `where` loop adds up the grams of the plants whose bits are set.

`Int` totals stay whole numbers, so `abs` and `>=` count the 6 ties with
the observed difference exactly; `Double` appears only in the printed
output. Arrays have no `combinations(ofCount:)` here: that method comes
from the Swift Algorithms package, which isn't installed.
