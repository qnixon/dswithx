Compared with C, the plumbing shrinks. A `std::vector` grows as you
`push_back`, so there's no `realloc`, and `std::getline` with a comma splits
each line. `std::sort` orders the values for the median, and
`std::accumulate` adds them up. C++ has no mean, median, or variance, so
there's nothing to skip.

Watch the `0.0` in `accumulate`. Its starting value sets the type it adds
in, so a plain `0` adds ints, and on 28.6, 43.8, and 11.5 it returns 82
instead of 83.9, with no warning even under `-Wall -Wextra -Werror`.
`std::println`, new in C++23, prints six decimals with `{:.6f}`.
