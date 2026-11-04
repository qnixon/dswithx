`z .^ (0:degree)'` broadcasts a column of scaled speeds against a row of
powers, building the whole matrix at once, and `Z' * Z` gives the normal
equations. Our `gauss` function runs the elimination: `argmax` finds the
pivot, `M[[col, pivot], :]` swaps two rows, and `.-=` updates a row in
place.

Base Julia's backslash, `A \ b`, would solve the system in one step; we
avoided it. Scaling matters here: on raw speeds, backslash on the degree-8
normal equations gives a training error of 0.073996, not 0.073821.
