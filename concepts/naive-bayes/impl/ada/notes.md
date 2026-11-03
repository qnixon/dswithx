We count training rows into an `Indefinite_Ordered_Maps` keyed by one
string, such as `has_link=yes|spam`, and a missing key counts as zero. The
features are an enumeration type, but `Feature'Image (Has_Link)` gives
`"HAS_LINK"`, so `To_Lower` turns it back into the column name. Labels and
each feature's distinct values go into `Indefinite_Ordered_Sets`, which
ignore repeats with `Include` and iterate in sorted order.

Ada's standard library has no naive Bayes, so scoring is written out: add
logs of the smoothed probabilities, and keep a label only when it scores
strictly higher. Because the set iterates alphabetically, an exact tie goes
to the first label.
