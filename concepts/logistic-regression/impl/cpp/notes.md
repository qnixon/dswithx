Each student is a `struct` holding a `std::array` of three inputs, the first
always 1 so that weight 0 acts as the intercept, plus the label. Two
`std::vector`s collect the training and test rows, so there's no `realloc`
as in C, and `std::inner_product` writes the weighted sum in one call.

Each step sums the whole gradient into a fresh array, then moves all three
weights in place. A `std::array` has no arithmetic, so `w - gradient` won't
compile and the update is a loop. Watch the `&` in `for (Example& row :
train)`: without it, the scaling loop would change copies and leave the rows
as they were.
