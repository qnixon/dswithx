Ada's containers and sort are generics: you make your own copy for your
types with `is new`, so `Float_Vectors` is a growable list of `Long_Float`,
and `Sort` is `Generic_Array_Sort` made for our array type. Types are
strict, so dividing the total by the count takes `Long_Float (N)` first.

Ada's standard library has no mean, median, or variance, so each is a
loop. Sorting is a general tool. There's no split function either, so
`Field` walks the commas with `Index`. Printing takes care too:
`Long_Float'Image` gives E notation, so `Put` with `Fore`, `Aft`, and
`Exp => 0` prints six plain decimals.
