Every matrix step is one APL product. The inner product `(⍉Z)+.×Z` builds
the whole correlation matrix, `M+.×⍵` multiplies it by the current vector,
and the outer product `PC1∘.×PC1` gives the table of vᵢ × vⱼ that
deflation subtracts. Power iteration needs no loop: `⍣` applies the
multiply-and-rescale step 1000 times from 1 0 0 0.

One parsing surprise: in GNU APL, `(f⍣STEPS)(≢M)↑1` raises a DOMAIN ERROR,
though the same line with a literal 1000 runs. We name the start vector
`START` first. The sign flip has no `if`: `V×¯1*V[1]<0` multiplies by ¯1
to the power 1 or 0.
