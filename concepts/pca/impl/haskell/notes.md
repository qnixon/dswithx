Here a matrix is a list of rows and a vector is a list of numbers, so a
matrix-vector product is ``map (`dot` v) m``: each row dotted with the vector.
One power-iteration step is `normalize . matVec m`, the two functions
joined with `.`, and `iterate` repeats it, building the endless list of
every step's vector. `!! 1000` picks the one we want, and laziness means
no step past it is ever computed.

`transpose` turns the rows of scores into columns for standardizing and
back again, and the correlation matrix is a list comprehension over pairs
of columns. Deflation is another comprehension. Base has no matrix type
and no eigenvalue routine, so every step is written out here.
