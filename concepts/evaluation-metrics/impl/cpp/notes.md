Each row becomes a `Part` struct holding a `bool` and a `double`. `report`
loops over the parts with a structured binding, which unpacks each struct
into `defective` and `score`, and sorts every part into one of four counts.
The metrics are ratios of those counts, cast to `double` before dividing.

For the AUC we split the scores into a defective vector and a good vector,
then compare every pair in two nested loops, 2 points for a win and 1 for a
tie, in a `long`. `std::ranges::count_if` counts the defective parts, and
every metric is written out by hand rather than called.
