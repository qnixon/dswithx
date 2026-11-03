Ada has no kNN classifier and no counter type, so we count votes the way
C and Pascal do: for each of the five nearest labels, a loop counts how
many of the five share it, and the first label to reach the top count
wins. Each variety is an `Unbounded_String`, since a plain `String` has a
fixed length, and `=` compares the text.

For each test seed we fill an array of distance-and-row records and sort
all 150 with `Generic_Array_Sort`. GNAT implements it as a heapsort, which
doesn't keep equal elements in order, so our `Nearer` comparison breaks
distance ties by row number.
