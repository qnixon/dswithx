APL tests every split at once, without a loop. `(P⍴2)⊤¯1+⍳2*P` writes each
number from 0 to 65,535 in base 2, giving a 16 by 65,536 table of 0s and
1s, one column per labeling. `(N=+⌿MASKS)/MASKS` keeps the 12,870 columns
with exactly 8 ones.

The inner product `GRAMS+.×MASKS` then multiplies and sums down every
column in one step, giving each split's chosen total. The grams are whole
numbers, so `≥` compares exact integers, and the 6 splits that tie the
observed difference all count.
