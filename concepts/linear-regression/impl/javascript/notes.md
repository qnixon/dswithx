JavaScript stays close to the formulas, with a little more ceremony than
Python. Node has no CSV parser, so `readRows` splits each line on commas and
uses `Object.fromEntries` to build an object keyed by header name. Arrays
have no `sum` and no `zip`, so a one-line `sum` helper wraps `reduce`, and
the cross-product pairs values by index:
`xs.map((x, i) => (x - meanX) * (ys[i] - meanY))`.

One thing we never had to think about is integer division. JavaScript has a
single number type, a 64-bit float, so `7 / 2` is `3.5` and no ratio here
can truncate. Its standard library has no regression or correlation
function, so there was no built-in to skip.
