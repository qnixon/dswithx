The classifier is the one from the k-nearest neighbors page, with `k`
passed in instead of fixed at 5. Two loops wrap it: one over the odd values
of k, and one over the 5 folds. `slice(start, end)` copies one block of 30
rows for the held-out fold, and `rest` spreads the slices before and after
it into a new array with `[...a, ...b]`. Neither call changes `train`.

Node's built-in modules have no cross-validation or kNN, and npm is removed
from this image, so no package could add one. `toSorted` is stable, so equal
distances keep file order with no index tie-breaker, and a `Map` counts the
votes.
