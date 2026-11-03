PHP has no regression or correlation function, so we write the sums out.
`array_sum` adds up each list, and `array_map` with a short `fn` squares
each deviation. For the cross-products, we hand `array_map` both columns
at once: it walks them side by side and passes one x and its y to each
call, much as `zip` does in Python.

PHP does have a CSV reader, `str_getcsv`, but no field here is quoted, so
`explode` splits each line on commas, and `array_search` finds each column
in the header.
