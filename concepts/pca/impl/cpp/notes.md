The correlation matrix is a `std::array` of four `std::array`s of four
doubles, so its size is part of its type, as in C. Unlike a C array, though,
a `std::array` can be returned from a function, so `mat_vec` simply returns
the product, one `std::inner_product` per row.

Watch the copy. `Matrix deflated = corr` copies all 16 entries, so
subtracting the first component from `deflated` leaves `corr` untouched.
That's the opposite of Java, where assignment shares the array, and in C,
assigning one array to another won't compile. The standard library has no
eigenvalue routine to skip, and libraries such as Eigen aren't installed.
