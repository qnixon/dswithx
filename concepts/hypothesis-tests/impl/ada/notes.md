We never shuffle at random. A recursive procedure, `Choose`, walks the
plants in order and either chooses each one or skips it, so it reaches
all 12,870 ways to pick 8 of the 16, and the p-value is exact. `Choose` is
nested inside the block that declares `Splits` and `As_Extreme`, so it
can update those counters directly, with no globals or extra parameters.

The `&` operator from `Ada.Containers.Vectors` joins the two groups into
one vector. Totals are `Integer`, so `>=` compares whole numbers, and the
6 exact ties all count.
