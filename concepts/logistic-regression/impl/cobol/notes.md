We expected fixed-point decimals to drift over 1000 steps, but they don't.
With 18 decimal places, `PIC S9(6)V9(18)`, and `ROUNDED` on every weight
update, the final weights and log-loss agree with Python's doubles to all
14 decimal places we printed, so there is no need for `COMP-2`
floating point. The cost is speed: the 150,000 calls to `FUNCTION EXP`
take about 10 seconds. Without them, the
loop runs in under 0.2 seconds.

Each step is a `PERFORM VARYING` over the rows that adds error × input
into three sums. At 260 lines, it's three and a half times the Python.
GnuCOBOL has `MEAN` and `STANDARD-DEVIATION` functions, but no regression.
