We read each score as whole thousandths, so "0.174" becomes 174:
`parse-integer` on the digits with the point removed. The thresholds become
500 and 300, and equal scores stay exactly equal.

Dividing two integers in Common Lisp gives an exact fraction, so precision
at 0.5 is 5/7, F1 is 5/9, and the AUC is 9931/11022 until `float` turns
each into a double for printing. The function is `print-metrics`, not
`report`: SBCL's default package imports `report` from its profiler, and
redefining it trips a package lock.
