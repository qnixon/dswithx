The distance to all 150 training seeds is one line: `(⍴TP)⍴P` repeats the
test point once per row, so subtracting, squaring, and summing each row
(`+/`) gives every distance at once. `K↑⍋D` takes the first five indices of
the sorted order. `⍋` is stable, which we checked on 10,000 values with
many ties, so equal distances keep file order.

The vote is array style too. `∪` lists the varieties in order of first
appearance, `∘.≡` compares each one with every neighbor, and `+/` counts
the matches. `⍳` finds the first position of the top count. There is no
nearest-neighbor built-in to avoid.
