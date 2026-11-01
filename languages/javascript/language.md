---
name: JavaScript
first_appeared: 1995
paradigm: Multi-paradigm (imperative, functional, prototype-based object-oriented)
toolchain: Node.js 26.13.0
image: node:26.13.0-trixie-slim
highlight: javascript
---

JavaScript was made for web browsers, and Node.js runs it on servers and the
command line. Its standard library has no numeric or data tools, so data
science in JavaScript usually means packages from npm. npm is removed from
this image, so none can be installed, and the work falls to array methods
like `map`, `filter`, and `reduce`, plus the `Math` object.

Each file here is an ES module that imports `readFileSync` from `node:fs`.
Node treats a `.js` file that uses `import` as a module even with no
`package.json` beside it, so no flag is needed.

## Quirks

- There is one number type, a 64-bit float: `typeof 3` and `typeof 3.5` are
  both `"number"`, and `7 / 2` is `3.5`.
- Node has no CSV parser among its built-in modules, so implementations
  here split lines on commas by hand.
- `sort()` with no comparator compares as strings: `[10, 9, 1].sort()` is
  `[1, 10, 9]`. Pass `(a, b) => a - b` to sort numbers.
- `==` on arrays compares identity, not contents: `[1, 2] == [1, 2]` is
  `false`.
