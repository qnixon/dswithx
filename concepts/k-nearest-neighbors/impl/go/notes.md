Go's standard library has no counter type, but a map does the job: a missing
key reads as zero, so `votes[n.label]++` counts a vote with no setup. We
keep track of the leader as we count, using a strict `>`, so a tied vote
would go to the label that reached the top count first.

For tie-breaking on distance, the choice of sort matters. `slices.SortFunc`
is documented as not guaranteed stable, so we use `slices.SortStableFunc`,
which keeps equal distances in file order, with `cmp.Compare` as the
comparison. Each neighbor is a small struct holding a distance and a label,
declared inside the function that uses it.
