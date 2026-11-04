APL needs no loops here. Each cell of the confusion matrix is the sum of a
mask of 1s and 0s, such as `+/FLAGGED∧DEFECTIVE`, and the ratios follow.

For the AUC, the outer product `D∘.>G` compares every defective score with
every good one at once, giving a 33 by 167 table of 1s and 0s, and `D∘.=G`
marks the ties. Doubling the wins, adding the ties, and summing the
flattened table gives the points. APL's `=` is tolerant: `⎕CT` defaults to
1E¯13, so `0.3=0.1+0.2` is 1. The scores here differ by at least 0.001, so
only true ties count.
