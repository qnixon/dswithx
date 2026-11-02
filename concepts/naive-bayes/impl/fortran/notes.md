Each email is a derived type with an array of three feature values and a
label. Fortran lets you take one component across a whole array: `train%label`
is every training label, so
`count(train%label == label .and. train%values(f) == row%values(f))` counts
one value within one label, and we add one for smoothing. Masks do the work a
dictionary does in other languages.

The labels are collected and insertion-sorted. In gfortran, `<` compares
character codes, so `"ham" < "Spam"` is false; all our labels are lowercase.
`maxloc` returns the first of equal scores, so an exact tie goes to the
alphabetically first label. gfortran has no naive Bayes intrinsic to avoid.
