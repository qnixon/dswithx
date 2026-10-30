<!-- Placeholder text: to be written. -->

**Easy:** the algorithm maps directly onto paragraphs: `ASSIGN-POINTS`,
`MOVE-CENTROIDS`, and a `DISTANCE` helper, looped with `PERFORM UNTIL` until
nothing changes. Keeping each point's cluster number in its table row makes
the "did anything change" check trivial.

**Hard:** paragraphs take no arguments, so `DISTANCE` works on whatever the
shared `I` and `J` happen to be, and every loop has to set them first.
Centroids are held to 12 decimal places so repeated division does not drift.
Building names like `centroid_2_x` takes a `STRING` statement plus an edited
picture to drop the leading zero.
