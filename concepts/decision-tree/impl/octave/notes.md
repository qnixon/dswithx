Core Octave has no tree function to skip, and the Octave Forge statistics
package isn't installed. We hold the tree as nested
structs. A leaf has one field, `label`, and a split keeps its `left` and
`right` children as whole structs inside it, so `grow` calls itself on each
side and `isfield(node, "label")` tells the two apart.

The split search has no loop over thresholds. Comparing the column of days
with a row of thresholds broadcasts to a table of days by thresholds, and
`sum` counts each column, so every threshold is scored at once. `min` returns
the first position of the smallest score, which makes the smallest threshold
win a tie.
