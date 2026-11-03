A vector is a table used as an array and the matrix is a table of row
tables, so `corr[i][j]` reads row i, column j, counting from 1. `mat_vec`
takes the dot product of each row with the vector, and power iteration is
a `for` loop that sets `v = normalize(mat_vec(m, v))` 1000 times.
`top_eigenvector` returns two values at once, which
`local value_1, pc_1 = ...` unpacks.

The built-in we skip doesn't exist here: Lua's `math` library has square
roots and trigonometry but no matrices or eigenvalues. LuaRocks has matrix
modules, but neither LuaRocks nor any module is installed, so
`require("matrix")` fails with "module 'matrix' not found".
