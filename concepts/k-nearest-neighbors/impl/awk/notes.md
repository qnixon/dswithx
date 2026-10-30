awk handles the reading well. A pattern like `$c_split == "train"` sends
each line to the right arrays, and associative arrays make each vote a
single `votes[label]++`. The program compares squared distances, which rank
neighbors the same way and skip the square root.

The search is where awk pushes back. POSIX awk has no sort function (mawk
answers `asort` with "function asort never defined"), so `classify` picks
the nearest unused seed five times over, marking picks in `used`. That's
five scans of all 150 training seeds per test seed. There are no records
either, so each seed lives in parallel arrays, `tx`, `ty`, and `tlab`, and
locals are declared as extra function parameters. In exchange it
runs unchanged on mawk and on the awk that ships with macOS.
