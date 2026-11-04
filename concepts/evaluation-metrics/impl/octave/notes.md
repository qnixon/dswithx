No loop sorts the parts into counts. `score >= threshold` compares the whole
column at once and gives a logical vector, and `&` and `!` combine it with
the labels, so each of the four counts is one `sum`.

For the AUC, `d > g'` compares a column of 33 defective scores with a row
of 167 good ones. Octave broadcasts the two into a 33-by-167 matrix of
every pairwise result, and `(:)` flattens it for `sum`. Ties count half
through the matching `==` matrix. Octave Forge packages, such as
statistics, aren't installed.
