COBOL gets the distances exactly right. Each feature is a fixed-point
decimal, `PIC S9(9)V9(6)`, and squared distances go into `PIC
S9(12)V9(12)`, so with two-decimal data nothing rounds. An exact tie really
compares equal. The two training seeds 0.13 mm from the test seed at 6.06 ×
3.21 both have a squared distance of exactly 0.0169, where floating point
produces two slightly different numbers.

Everything else is by hand. With no sort-by-key or counter, `CLASSIFY` runs
five selection scans over `WS-DIST` with a strict `<`, marking picks in
`WS-USED`, and `ADD-VOTE` keeps a small table of labels and tallies. Tables
are fixed in size (`OCCURS 5000 TIMES`), and at 214 lines the program is
nearly five times as long as the 45-line Python. There is no kNN built-in to
skip.
