<!-- Placeholder text: to be written. -->

**Easy:** squared distances. The data has two decimal places, so every
squared distance is exact in a fixed-point field, and ties compare as truly
equal instead of differing in the last floating-point bit.

**Hard:** there is no sort-by-key or counter to lean on. COBOL's table `SORT`
is not guaranteed stable, so the five nearest seeds are found by five
selection scans with a strict `<` (ties go to the earlier training row), and
the vote is tallied in a small hand-managed table of labels.
