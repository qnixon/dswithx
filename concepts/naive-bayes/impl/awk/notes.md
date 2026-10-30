awk is a natural fit for counting categories. Associative arrays start every
entry at zero, so `value_count[f "," value "," label]++` counts a feature,
value, and label as the rows stream past. POSIX awk has no nested arrays, so
the three parts are joined into one string key. `log` is built in.

The tie rule takes more work. POSIX awk has no sort, and `for (k in array)`
visits keys in an unspecified order: the same four keys came back in
different orders from mawk and the macOS awk. So `add_label` inserts each new
label into a sorted array as it's first seen. Local variables are faked as
extra function parameters, like `i` in `add_label(name,    i)`. The program
runs unchanged on mawk, which the tests use, and on macOS awk.
