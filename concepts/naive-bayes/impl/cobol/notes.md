<!-- Placeholder text: to be written. -->

**Easy:** counting. Nested `OCCURS` tables give a natural
feature-by-value-by-label grid of counts, and categorical data needs no
number parsing at all.

**Hard:** there are no dictionaries, so every label and value is looked up by
a linear scan and added to its table the first time it is seen. Each log
score is built as a sum of `FUNCTION LOG` of whole counts (log a - log b
rather than log(a / b)), so no quotient is truncated to the field's decimals
before the log is taken.
