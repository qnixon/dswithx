We never shuffle at random. A recursive function, `choose`, walks every way
to pick 8 of the 16 plants for the compost label, carrying a running total
as it goes, so we add up each split once and visit all 12,870 of them. Its
loop stops while enough plants remain to fill the group, so no branch is a
dead end.

Because both groups have 8 plants, comparing totals is the same as comparing
means, and the totals stay whole numbers, so `>=` never meets a near-tie.
