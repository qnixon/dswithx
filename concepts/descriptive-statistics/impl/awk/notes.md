<!-- Placeholder text: to be written. -->

**Easy:** reading the data. awk splits each line into fields on its own, and
the header lookup is a three-line loop. Floating-point math and `printf` are
built in.

**Hard:** the median. POSIX awk has no sort function, so each value is
inserted into a sorted array as it is read. That is fine for 120 rows, but
insertion sort is quadratic, so it would crawl on large files.
