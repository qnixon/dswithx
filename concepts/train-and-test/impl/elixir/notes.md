A matrix is a list of row lists, and nothing is changed in place, so the
elimination is recursive. `Enum.max_by` picks the row with the largest
first entry (partial pivoting), `List.delete` removes it, and a
comprehension subtracts a multiple of it from every other row. The smaller
system that's left goes back into `eliminate`.

Back substitution splits off each row's right-hand side with
`Enum.split(rest, -1)`. Powers use `**`, and each normal-equation entry
is an `Enum.sum` over the training drives. No solver or fitting function
is called.
