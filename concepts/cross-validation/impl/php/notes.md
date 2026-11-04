The kNN classifier is the same as on the k-nearest neighbors page, with `$k`
passed in instead of fixed at 5. Two loops wrap it: one over the odd values
of k, and one over the 5 folds. `array_slice` builds each split. It
takes a start and a length, not an end, and numbers the copy from 0 again,
so `array_merge` can join the pieces before and after the held-out fold.

PHP has no cross-validation function, and PHP-ML and Rubix ML, the
Composer packages that offer one, aren't installed. As on the kNN
page, an array keyed by label counts the vote, and `usort` breaks distance
ties by row number, so equal distances keep the earlier training seed.
