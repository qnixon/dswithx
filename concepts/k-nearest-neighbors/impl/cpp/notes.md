C++ has no kNN classifier, so we build one from a `struct Seed`, two
`std::vector`s, and a `std::map`. Unlike C, the variety is a `std::string`,
so `==` compares the labels themselves, with no `strcmp`.

For each test seed we sort pointers to all 150 training seeds by
`std::hypot` distance. `std::sort` isn't stable, so we use
`std::stable_sort`, which keeps equal distances in file order. On this data
plain `std::sort` reorders the five nearest for 4 of the 50 test seeds but
still gets 47 right. The `std::map` counts votes, but it keeps its keys
alphabetical, so we walk the nearest five again and the first label to reach
the top count wins.
