We enumerate the splits with a mask: a vector of eight 0s then eight 1s,
where 1 means "labeled compost". `std::next_permutation` steps the mask to
its next arrangement in sorted order and returns false after the last one.
Because equal values are interchangeable, it visits each distinct
arrangement once: 12,870 of them, not 16 factorial.

`std::transform_reduce` multiplies each plant's grams by its 0 or 1 and adds
the products, giving the chosen total. Totals stay `long` integers, so `>=`
counts the 6 exact ties correctly.
