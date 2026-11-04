This builds on the COBOL kNN program, so distances are exact fixed-point
decimals. That matters here: held-out seed 77 has two neighbors, training
seeds 10 and 146, at a squared distance of exactly 0.0325, tied for
seventh. COBOL keeps seed 10, by file order, where double-precision
floating point puts 146 slightly nearer. The vote comes out the same either way.

Each seed's `WS-FOLD` is its row number less 1, divided by 30 into a whole
number. `FIND-NEAREST` marks the held-out fold as used, then picks the 15
nearest once, and `VOTE` reads the first k for every odd k. A test seed
uses fold 9, which no row has. There's no cross-validation built-in to
skip.
