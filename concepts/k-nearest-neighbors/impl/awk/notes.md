<!-- Placeholder text: to be written. -->

**Easy:** splitting rows into training and test sets. A pattern such as
`$c_split == "train"` picks the lines, and associative arrays make counting
the votes a one-liner.

**Hard:** finding the 5 nearest seeds. With no sort function, the program
picks the nearest unused seed five times over, which is simple but scans all
150 training rows five times for every test seed. There are no records
either, so each seed lives in three parallel arrays.
