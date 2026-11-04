This builds on the BASIC kNN program, with the same parallel arrays and
selection scans with a strict `<`. A seed's fold is `INT((J - 1) / S)`,
where `S` is 30, and seeds in the held-out fold start out marked as used in
`U`, so the scans skip them. Test seeds pass `HF = -1`, a fold no row has.

Each held-out seed finds its 15 nearest only once. The k nearest are the
first k of those, so one `FOR K = 1 TO NK STEP 2` loop votes for every k
from the same list. BASIC has no
sort or cross-validation to avoid; everything is written out.
