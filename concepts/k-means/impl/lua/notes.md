Each point is a small table with named fields, `{x = 1.25, y = 1.66}`, so
we write `p.x` and `p.y`. Lua has no distance function, so `distance`
writes out the square root of the summed squares, and `nearest` replaces
its best only on a strictly smaller distance, so a tie keeps the lower
index.

To notice that nothing changed, we compare the whole assignment with the
last one. Lua's `==` can't do that: on two tables it asks whether they are
the same table, so `{1, 2} == {1, 2}` is `false`. A short `same` function
compares them element by element instead. Lua has no clustering or
statistics library to avoid.
