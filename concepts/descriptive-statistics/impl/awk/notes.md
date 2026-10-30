awk was made for files like this one. It splits each line into fields for
you, so finding the `minutes` column in the header takes a three-line loop,
and running totals need no setup because awk starts every variable at zero.

The median is the hard part. POSIX awk has no sort function, so we insert
each value into a sorted array as it's read. That's insertion sort, fine
for 120 rows but slow for large files. In exchange, the program sticks to
POSIX awk, so it runs unchanged on both awks we test: mawk, which the tests
use, and the one that ships with macOS.
