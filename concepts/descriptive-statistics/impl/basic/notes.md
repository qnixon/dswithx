This is BASIC as many people first met it: numbered lines, `GOTO`, and
`GOSUB`. A subroutine is just a block of lines ending in `RETURN`. It takes
no arguments, so to print a result, the caller sets `L$` and `Y` and then
runs `GOSUB 3000`. Every variable is global, and every array is given a
fixed size up front with `DIM`, so `X` holds at most 1,000 values.

There's no sort, so lines 2000 to 2080 are an insertion sort built from
`IF` and `GOTO`. Splitting a CSV line uses `INSTR` and `MID$`, and `VAL`
turns the text into a number. `PRINT USING "#.######"` prints six decimals
and widens the field when a number needs more room.
