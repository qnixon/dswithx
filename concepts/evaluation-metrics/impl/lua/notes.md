Each part becomes a small table with a `defective` flag and a `score`, and
one loop per threshold sorts every part into one of four counts: true
positives, false positives, false negatives, and true negatives. Every
metric is a ratio of those counts.

`tonumber("0.174")` gives a float, and equal strings in the file give
equal floats, so the three tied pairs compare as ties. The AUC loop scores
2 for a win and 1 for a tie across all 33 times 167 pairs. Lua's `/`
always returns a float, so no division needs a cast. LuaRocks isn't
installed.
