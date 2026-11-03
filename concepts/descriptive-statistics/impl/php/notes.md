A PHP array is an ordered map from keys to values. With the keys 0, 1, 2,
and so on, as here, it acts as a list: `$values[0]` is the smallest time
once `sort` has put them in order, and `count` gives their number.

PHP has no mean, median, or variance, so each is written out, with
`array_sum` for the totals. `array_map` and a short `fn` square each
deviation. PHP does have a CSV reader, `str_getcsv`, but no field
here is quoted, so `explode` simply splits each line on commas. `intdiv` finds the median's middle, because `/` gives
a whole number only when the division comes out even: `10 / 2` is 5, but
`9 / 2` is 4.5.
