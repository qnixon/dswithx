The vector and matrix are fixed-size arrays, `[f64; 4]` and `[[f64; 4]; 4]`,
named `Vector` and `Matrix`. The length is part of the type: passing a
three-element array to `dot` is a compile error, "expected an array with a
size of 4, found one with a size of 3". Arrays of `f64` are `Copy`, so
`normalize` takes its vector by value with no borrow, and array `map` returns
another array, so `v.map(|x| -x)` flips the sign without allocating a `Vec`.
The standard library has no linear algebra or eigenvalue routine, so there
was no built-in to skip.
