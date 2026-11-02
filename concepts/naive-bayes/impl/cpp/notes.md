Where C recounts training rows for every score, we count once. A `std::map`
keyed by a `std::tuple` of feature, value, and label holds the value counts,
since tuples compare field by field, and a second map counts labels.
`operator[]` inserts a zero for a missing key, so `++` starts counting at 1;
scoring uses `find` instead, which leaves the map alone.

A `std::map` keeps its keys sorted, so looping over the label counts tries
labels alphabetically, and only a strictly higher score replaces the best,
so an exact tie goes to the first. The order is by character code, so
`"Spam"` would sort before `"ham"`. C++ has no naive Bayes function to avoid.
