Points are two-element arrays, and destructuring in the parameter list,
`function distance([x1, y1], [x2, y2])`, unpacks them where they arrive.
`nearest` is a plain loop, because arrays have no `min` with a key;
replacing the best only on a strictly smaller distance sends a tie to the
lower index.

The trap is the stopping test. `==` on two arrays compares identity, not
contents: `[1, 2] == [1, 2]` is `false`. Written the Python way, the test
never sees the assignments settle, and the loop runs all 100 iterations
before it stops. `sameAssignment` compares element by element instead. The
standard library has no clustering to skip.
