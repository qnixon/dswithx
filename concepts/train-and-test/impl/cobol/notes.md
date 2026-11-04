We hold the augmented normal equations in a table of rows, each row a
group item of ten entries. That makes the pivot swap three `MOVE`s
through a spare row, since a group `MOVE` copies every entry at once.
Each drive's powers of z come from repeated multiplication into a
small table, so we never use `**` on the scaled speeds.

Values are fixed-point decimals with 18 places. The degree-8 system
divides by pivots as small as 0.00006, yet all 16 errors still agree
with Python's doubles to within 1e-11. GnuCOBOL has no matrix or
polynomial-fitting function to skip.
