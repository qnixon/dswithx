Each row becomes a `seed` struct, and `defstruct` writes the readers, such
as `seed-length`, for us. To find the 5 nearest, we `stable-sort` a copy of
all 150 training seeds, keyed on distance, and keep the first 5 with
`subseq`. Only `stable-sort` is guaranteed to keep equal distances in file
order; in our test, SBCL's plain `sort` reordered ties in a vector.

For the vote, `remove-duplicates` with `:from-end t` lists each variety in
the order the neighbors came, `count` tallies it, and only a strictly larger
count takes the lead. No kNN or distance function is called.
