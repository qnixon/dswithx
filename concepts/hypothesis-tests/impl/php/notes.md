A recursive generator, `chosen_totals`, walks the plants in order and
yields the compost total of each split. At each plant it either takes the
plant or skips it, and `yield from` passes along everything the nested
call yields. The main loop uses `foreach` to pull the 12,870 totals one at
a time, so no list of splits is ever built.

The grams are cast with `(int)`, so totals and the `>=` test stay exact.
PHP's `/` returns an integer when the division is exact, as in 8 / 4, and
a float otherwise. Composer packages aren't installed.
