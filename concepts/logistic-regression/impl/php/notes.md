Each example is a two-item array, the features and the label, and
`foreach ($test as [$x, $y])` unpacks it as the loop runs. The gradient
step uses plain loops: one pass over the students adds each error times
each input to a running gradient, and a second loop moves every weight
only once the whole gradient is known.

PHP has no regression, classifier, or matrix type, so `sigmoid`, `dot`,
and the `$scale` closure are written out, with `exp`, `log`, and `sqrt`
as the only math built-ins. Called with several arrays, `array_map`
walks them side by side, which is how `$scale` pairs each value with
its mean and standard deviation.
