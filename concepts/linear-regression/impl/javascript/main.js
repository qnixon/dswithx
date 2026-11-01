// Simple linear regression by least squares, using only Node's built-in modules.
// Fits score = intercept + slope * hours. JavaScript has no regression
// function to skip; the sums are written out so the formulas stay visible.

import { readFileSync } from "node:fs";

const X = "hours";
const Y = "score";

// Node has no CSV parser. No field here is quoted, so we split on commas and
// turn each line into an object keyed by the header names.
function readRows(path) {
  const [header, ...lines] = readFileSync(path, "utf8").trim().split("\n");
  const names = header.split(",");
  return lines.map((line) => {
    const fields = line.split(",");
    return Object.fromEntries(names.map((name, i) => [name, fields[i]]));
  });
}

const sum = (numbers) => numbers.reduce((acc, x) => acc + x, 0);

const rows = readRows(process.argv[2]);
const xs = rows.map((row) => Number(row[X]));
const ys = rows.map((row) => Number(row[Y]));

const n = xs.length;
const meanX = sum(xs) / n;
const meanY = sum(ys) / n;

// Sums of squared deviations and of cross-products.
const sxx = sum(xs.map((x) => (x - meanX) ** 2));
const syy = sum(ys.map((y) => (y - meanY) ** 2));
const sxy = sum(xs.map((x, i) => (x - meanX) * (ys[i] - meanY)));

const slope = sxy / sxx;
const intercept = meanY - slope * meanX;
const r = sxy / Math.sqrt(sxx * syy);

console.log(`count ${n}`);
console.log(`slope ${slope.toFixed(6)}`);
console.log(`intercept ${intercept.toFixed(6)}`);
console.log(`r ${r.toFixed(6)}`);
console.log(`r_squared ${(r * r).toFixed(6)}`);
