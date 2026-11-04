We split each line on commas, find the two columns by name in the header,
and turn every row into an object with a boolean `defective` and a numeric
`score`. One loop per threshold sorts every part into one of four counts:
true positives, false positives, false negatives, and true negatives. Every
metric is a ratio of those counts.

The AUC compares every defective part with every good one, 33 times 167
pairs, scoring 2 for a win and 1 for a tie. JavaScript has one number type,
a double, but `Number("0.300") === 0.3` holds, so tied scores in the file
stay tied.
