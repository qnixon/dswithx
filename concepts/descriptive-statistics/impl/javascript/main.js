// Descriptive statistics on one CSV column, using only Node's built-in modules.
// JavaScript has no statistics library, so every formula is written out.

import { readFileSync } from "node:fs";

const COLUMN = "minutes";

// Node has no CSV parser. This file has no quoted fields, so splitting each
// line on commas is enough; the header row tells us which field to read.
function readColumn(path, column) {
  const [header, ...lines] = readFileSync(path, "utf8").trim().split("\n");
  const index = header.split(",").indexOf(column);
  return lines.map((line) => Number(line.split(",")[index]));
}

function median(sortedValues) {
  const n = sortedValues.length;
  const middle = Math.floor(n / 2);
  if (n % 2 === 1) return sortedValues[middle];
  return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
}

const values = readColumn(process.argv[2], COLUMN);
// sort() compares as strings unless given a comparator: [10, 9].sort() is [10, 9].
values.sort((a, b) => a - b);

const n = values.length;
const total = values.reduce((acc, x) => acc + x, 0);
const mean = total / n;
// Sample variance divides by n - 1, not n (Bessel's correction).
const variance = values.reduce((acc, x) => acc + (x - mean) ** 2, 0) / (n - 1);

const results = [
  ["sum", total],
  ["mean", mean],
  ["median", median(values)],
  ["min", values[0]],
  ["max", values.at(-1)],
  ["range", values.at(-1) - values[0]],
  ["variance", variance],
  ["std_dev", Math.sqrt(variance)],
];

console.log(`count ${n}`);
for (const [name, value] of results) {
  console.log(`${name} ${value.toFixed(6)}`);
}
