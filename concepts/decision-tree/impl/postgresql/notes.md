A tree is recursive, and `WITH RECURSIVE` grows it one level at a time.
Each row is a node, named by its path from the root (`''`, `'L'`, `'LR'`),
holding an array of the ids of the days that reach it; this tree takes 13
rows. The recursive term can't read the tree from a subquery ("recursive
reference ... must not appear within a subquery") or aggregate it, so each
node's split search runs in `LATERAL` subqueries over its own `members`.

Test days ride along in those arrays, so each one lands in the leaf that
predicts it, with no walk down the tree. Sorting paths in the `"C"`
collation gives preorder. Core PostgreSQL has no decision tree to skip.
