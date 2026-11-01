The vector and matrix are fixed-size arrays, `type vector [k]float64` and
`type matrix [k]vector`. Assigning an array copies every element, so
`deflated := corr` is a fresh matrix we can change without touching `corr`.
A slice would share storage: after `t := s; t[0][0] = 99`, `s` changes too.
Arrays also fill unlisted entries with zero, so the starting vector
`vector{1}` is `[1 0 0 0]`, and `normalize` can scale its argument in place
because it holds a copy. Go's standard library has no linear algebra
package and no eigenvalue routine, so there was no built-in to skip.
