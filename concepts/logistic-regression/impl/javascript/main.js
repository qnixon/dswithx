// Logistic regression by gradient descent, using only Node's built-in modules.
// Predicts whether a student passed from study hours and sleep. Each feature
// is rescaled with the training rows' mean and standard deviation, then the
// weights start at zero and take 1000 fixed steps of batch gradient descent
// on the average log-loss.

import { readFileSync } from "node:fs";

const FEATURES = ["hours", "sleep"];
const LABEL = "passed";
const LEARNING_RATE = 0.5;
const STEPS = 1000;

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
const sigmoid = (z) => 1 / (1 + Math.exp(-z));
const dot = (w, x) => sum(w.map((wj, j) => wj * x[j]));

const rows = readRows(process.argv[2]).map((row) => ({
  x: FEATURES.map((name) => Number(row[name])),
  y: Number(row[LABEL]),
  split: row.split,
}));
const train = rows.filter((row) => row.split === "train");
const test = rows.filter((row) => row.split === "test");
const n = train.length;

// Scale each feature to mean 0 and (sample) standard deviation 1, using the
// training rows only. The leading 1 multiplies the intercept.
const means = FEATURES.map((_, j) => sum(train.map((row) => row.x[j])) / n);
const sds = FEATURES.map((_, j) =>
  Math.sqrt(sum(train.map((row) => (row.x[j] - means[j]) ** 2)) / (n - 1)),
);
const scale = (x) => [1, ...x.map((v, j) => (v - means[j]) / sds[j])];

const xs = train.map((row) => scale(row.x));
const ys = train.map((row) => row.y);

let weights = [0, 0, 0];
for (let step = 0; step < STEPS; step++) {
  // Gradient of the average log-loss: the mean of (p - y) times each input.
  // map builds a new array, so every gradient uses the old weights.
  const errors = xs.map((x, i) => sigmoid(dot(weights, x)) - ys[i]);
  const gradient = weights.map((_, j) => sum(errors.map((e, i) => e * xs[i][j])) / n);
  weights = weights.map((w, j) => w - LEARNING_RATE * gradient[j]);
}

const logLoss =
  -sum(
    xs.map((x, i) => {
      const p = sigmoid(dot(weights, x));
      return ys[i] * Math.log(p) + (1 - ys[i]) * Math.log(1 - p);
    }),
  ) / n;

const predict = (x) => (sigmoid(dot(weights, scale(x))) >= 0.5 ? 1 : 0);
const correct = test.filter((row) => predict(row.x) === row.y).length;

console.log(`train_count ${n}`);
console.log(`test_count ${test.length}`);
console.log(`intercept ${weights[0].toFixed(6)}`);
console.log(`weight_hours ${weights[1].toFixed(6)}`);
console.log(`weight_sleep ${weights[2].toFixed(6)}`);
console.log(`log_loss ${logLoss.toFixed(6)}`);
console.log(`correct ${correct}`);
console.log(`accuracy ${(correct / test.length).toFixed(6)}`);
