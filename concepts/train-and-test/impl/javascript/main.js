// Train and test error for polynomials of degree 1 to 8, using only Node's
// built-in modules.
//
// Each polynomial is fitted by least squares to the training drives only:
// we build the normal equations and solve them by Gaussian elimination. Then
// we measure its root-mean-square error on the training drives and on the
// test drives it never saw.

import { readFileSync } from "node:fs";

const MAX_DEGREE = 8;

// No field here is quoted, so we split on commas and find columns by name.
// Each drive becomes [speed, litres], sorted into train or test.
function read(path) {
  const [header, ...lines] = readFileSync(path, "utf8").trim().split("\n");
  const columns = header.split(",");
  const iSpeed = columns.indexOf("speed");
  const iLitres = columns.indexOf("litres");
  const iSplit = columns.indexOf("split");
  const train = [], test = [];
  for (const line of lines) {
    const fields = line.split(",");
    const point = [Number(fields[iSpeed]), Number(fields[iLitres])];
    (fields[iSplit] === "train" ? train : test).push(point);
  }
  return { train, test };
}

// Solve a x = b by Gaussian elimination with partial pivoting.
function solve(a, b) {
  const n = b.length;
  const m = a.map((row, i) => [...row, b[i]]); // augmented matrix, copied
  for (let col = 0; col < n; col++) {
    // Swap up the row with the largest entry in this column, which keeps
    // the rounding error small.
    let pivot = col;
    for (let r = col + 1; r < n; r++) {
      if (Math.abs(m[r][col]) > Math.abs(m[pivot][col])) pivot = r;
    }
    [m[col], m[pivot]] = [m[pivot], m[col]];
    for (let r = col + 1; r < n; r++) {
      const factor = m[r][col] / m[col][col];
      for (let c = col; c <= n; c++) m[r][c] -= factor * m[col][c];
    }
  }
  // Back substitution, from the last unknown up.
  const x = new Array(n).fill(0);
  for (let r = n - 1; r >= 0; r--) {
    let total = m[r][n];
    for (let c = r + 1; c < n; c++) total -= m[r][c] * x[c];
    x[r] = total / m[r][r];
  }
  return x;
}

// Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i
// of Z is 1, z_i, z_i^2, ..., z_i^degree.
function fit(points, degree, scale) {
  const size = degree + 1;
  const a = Array.from({ length: size }, () => new Array(size).fill(0));
  const b = new Array(size).fill(0);
  for (const [x, y] of points) {
    const z = scale(x);
    for (let i = 0; i < size; i++) {
      b[i] += y * z ** i;
      for (let j = 0; j < size; j++) a[i][j] += z ** (i + j);
    }
  }
  return solve(a, b);
}

function rmse(coefs, points, scale) {
  let total = 0;
  for (const [x, y] of points) {
    const z = scale(x);
    const predicted = coefs.reduce((acc, c, i) => acc + c * z ** i, 0);
    total += (predicted - y) ** 2;
  }
  return Math.sqrt(total / points.length);
}

const { train, test } = read(process.argv[2]);

// Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
// largest entry at degree 8) would swamp the small ones and make the
// equations hard to solve accurately.
const speeds = train.map(([x]) => x);
const low = Math.min(...speeds);
const high = Math.max(...speeds);
const mid = (low + high) / 2, half = (high - low) / 2;
const scale = (x) => (x - mid) / half;

console.log(`train_count ${train.length}`);
console.log(`test_count ${test.length}`);
const errors = [];
for (let degree = 1; degree <= MAX_DEGREE; degree++) {
  const coefs = fit(train, degree, scale);
  errors.push([degree, rmse(coefs, train, scale), rmse(coefs, test, scale)]);
}
for (const [degree, trainError] of errors) {
  console.log(`train_rmse_d${degree} ${trainError.toFixed(6)}`);
}
for (const [degree, , testError] of errors) {
  console.log(`test_rmse_d${degree} ${testError.toFixed(6)}`);
}
