The augmented matrix is an array of row arrays, built with the spread
operator: `[...$row, $b[$i]]`. Swapping two rows is one destructuring
assignment, `[$m[$col], $m[$pivot]] = ...` with the pair reversed on the
right. PHP passes arrays by value, so `solve` works on its own copy.

There's no matrix type or solver to skip, so elimination and back
substitution are `for` loops. `$scale` is an arrow function, `fn`, which
picks up `$mid` and `$half` from the code around it without a `use` list.
