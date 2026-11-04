We keep each score as whole thousandths in a `PIC 9(4)` field: `NUMVAL`
reads "0.174", and multiplying by 1000 stores exactly 174. The thresholds
become 500 and 300, so every comparison is between exact integers, and the
3 tied pairs compare equal.

`REPORT-THRESHOLD` sorts the parts with `EVALUATE ... ALSO ...`, which tests
two conditions at once, flagged and defective, with one `WHEN` line per
cell of the confusion matrix. The AUC is two nested `PERFORM VARYING` loops
over the table, adding 2 points for a win and 1 for a tie. The ratios are
fixed-point decimals, rounded to 6 places for printing.
