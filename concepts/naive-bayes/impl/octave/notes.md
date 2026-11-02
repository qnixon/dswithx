We keep no table of counts. `strcmp` compares a whole column of strings with
one value and returns a logical vector, so
`sum(in_label & strcmp(train_values{f}, v))` counts the training rows with
this label and this value. `cellfun` repeats that for every test row and
collects the counts in a vector, and the scores fill a test-by-label matrix.

`unique` lists the labels sorted by character code, so `"Spam"` would sort
before `"ham"`; ours are all lowercase. `max(scores, [], 2)` returns the
first of equal scores, so an exact tie goes to the alphabetically first
label. Core Octave has no naive Bayes to avoid, and the statistics package
isn't installed.
