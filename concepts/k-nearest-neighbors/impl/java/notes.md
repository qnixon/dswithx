Each seed is a `record`, a one-line class for which Java writes the
constructor, the accessors, `equals`, and `toString`. We measure distance
with `Math.hypot`, collect a `Neighbor` record for every training seed, and
sort them with `List.sort`, which Java documents as stable, so equal
distances keep file order. For the 0.13 mm pair, `Math.hypot` gives the same
0.1299999999999999 and 0.13000000000000037 that Python does.

Java has no counter type, so `Collectors.groupingBy` with
`Collectors.counting()` turns the five nearest into a map from variety to
votes. Labels are compared with `equals`, since `==` on strings compares
objects: the `"train"` that `split` returns isn't `==` to the literal.
