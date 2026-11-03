Lua keeps everything in tables. Here a table is an array of the commute
times: indexes start at 1, `#values` is its length, and `values[n]` is the
last one. `ipairs` walks it in order.

Lua's standard library has no mean, median, or variance, so each is a
loop. Sorting is a general tool: `table.sort` orders the values in place.
There's no CSV reader or split function either, so `gmatch("[^,]+")`, a
Lua pattern, finds each field between commas, and `tonumber` turns it into
a number. Watch the two divisions: `/` always gives a float, while `//`
rounds down to an integer, which the median uses to find the middle.
