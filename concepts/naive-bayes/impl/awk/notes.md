<!-- Placeholder text: to be written. -->

**Easy:** counting. Associative arrays with string keys such as
`"1,yes,spam"` count every (feature, value, label) combination as the rows
stream past, and `log` is built in.

**Hard:** the alphabetical tie rule. POSIX awk has no sort, and `for (k in
array)` visits keys in an unspecified order, so the labels are kept in a
hand-sorted array as they are first seen. Local variables also have to be
faked as extra function parameters.
