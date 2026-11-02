BASIC has no sort, record type, or dictionary, so we keep each seed's
length, width, and variety in three parallel arrays, one set for training
and one for testing. A row goes to the training or test set through
`IF ... THEN GOSUB 1300 ELSE GOSUB 1400`.

For each test seed we store all 150 distances, then pick the nearest unused
training seed five times over, marking each pick in `U`. The search starts
from `BD = 1E+30` and uses a strict `<`, so on an exact tie the earlier
row wins. The vote counts how many of the five share each neighbor's
variety, comparing strings with a plain `=`, and the first to reach the
most votes wins.
