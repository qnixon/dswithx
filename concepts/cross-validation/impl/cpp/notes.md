The kNN classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Cross-validation adds two loops: one over
the odd values of k, and one over the 5 folds.

The held-out fold is a `std::span`, a view of 30 rows inside the training
vector, so nothing is copied. The other 120 rows go into a vector of
pointers, in file order, which `std::stable_sort` then sorts by distance, so
equal distances keep the earlier seed. The standard library has no
cross-validation, and none of the C++ machine learning libraries, such as
mlpack, is installed, so every step is written out.
