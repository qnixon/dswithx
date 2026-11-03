Each example is a small table, `{ x = x, y = y }`, read as `e.x` and
`e.y`. Inside each of the 1000 steps, a loop over the students adds every
error times input to a fresh `gradient` table, and only after that loop
ends does a second loop update `weights` in place, so every weight moves by
the same gradient.

Lua's standard library has no regression, classifier, or matrix type, so
there was no built-in to skip; `sigmoid`, `dot`, and `scale` are short
functions. The prediction uses `p >= 0.5 and 1 or 0`, Lua's stand-in for a
conditional expression. The accuracy needs no conversion, since `/` always
gives a float: `37 / 50` is 0.74.
