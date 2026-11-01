Each step replaces the weights with a new array, `weights.map(...)`, so
every part of the gradient is computed from the old weights, as the method
requires. A leading 1 joins the scaled features with spread syntax:
`[1, ...x.map(...)]`.

The trap is the label. `Number(row[LABEL])` looks optional, because
arithmetic converts strings for you: `sigmoid(...) - "1"` is a number, and
with string labels the weights train to exactly the same values. But strict
equality doesn't convert, and `1 === "1"` is `false`, so every prediction
would miss and `correct` would be 0. The standard library has no logistic
regression, so there was no built-in to skip.
