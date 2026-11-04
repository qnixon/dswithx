Each row becomes a `Part` record, a one-line immutable class whose
constructor and accessors Java writes for us. `report` sorts the parts into
four counts at a threshold, and every metric is a ratio of those counts,
cast to `double` first because `int / int` drops the fraction.

The AUC splits the scores into two `List<Double>` and compares every pair.
The loop variables are the primitive `double`, which matters: `==` on two
boxed `Double` objects compares references, so two parsed copies of 0.174
come out unequal and the 3 ties would be lost. A win adds 2 points and a
tie 1, in a `long`, until the final division.
