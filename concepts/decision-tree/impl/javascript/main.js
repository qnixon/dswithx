// A decision tree classifier (CART with Gini impurity), using only Node's
// built-in modules. Grows a tree on the training days by always making the
// split that leaves the two sides purest, then predicts rain for the test
// days. Prints the tree in preorder: each node is either a split (feature and
// threshold) or a leaf (its prediction).

import { readFileSync } from "node:fs";

const FEATURES = ["humidity", "pressure", "wind"];
const MAX_DEPTH = 3;
const MIN_SIZE = 5;

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

const countYes = (days) => days.filter((day) => day.rain === "yes").length;

// Chance that two days drawn at random (with replacement) disagree.
function gini(days) {
  const p = countYes(days) / days.length;
  return 1 - p * p - (1 - p) * (1 - p);
}

// An even split predicts "no".
const majority = (days) => (countYes(days) > days.length / 2 ? "yes" : "no");

function partition(days, f, threshold) {
  return [days.filter((day) => day.x[f] <= threshold), days.filter((day) => day.x[f] > threshold)];
}

// The split with the lowest weighted Gini impurity. Features are tried in
// column order and thresholds from smallest to largest; only a strictly lower
// score replaces the best so far.
function bestSplit(days) {
  let best = null;
  FEATURES.forEach((_, f) => {
    // A Set drops repeats. The comparator matters: with none, sort() would
    // compare the numbers as strings.
    const values = [...new Set(days.map((day) => day.x[f]))].sort((a, b) => a - b);
    for (let i = 1; i < values.length; i++) {
      const threshold = (values[i - 1] + values[i]) / 2;
      const [left, right] = partition(days, f, threshold);
      const score = (left.length * gini(left) + right.length * gini(right)) / days.length;
      if (best === null || score < best.score) best = { score, feature: f, threshold };
    }
  });
  return best;
}

// A leaf is { label }; a split is { feature, threshold, left, right }. Plain
// objects need no class: the presence of `label` tells the two apart.
function grow(days, depth = 0) {
  const impurity = gini(days);
  if (impurity === 0 || days.length < MIN_SIZE || depth === MAX_DEPTH) {
    return { label: majority(days) };
  }
  const split = bestSplit(days);
  if (split === null || split.score >= impurity) {
    return { label: majority(days) }; // no split makes the sides purer
  }
  const { feature, threshold } = split;
  const [left, right] = partition(days, feature, threshold);
  return { feature, threshold, left: grow(left, depth + 1), right: grow(right, depth + 1) };
}

function predict(node, x) {
  while (!("label" in node)) {
    node = x[node.feature] <= node.threshold ? node.left : node.right;
  }
  return node.label;
}

// Every node, parents before children, left subtree before right. A
// generator function (function*) hands back one node per yield.
function* preorder(node) {
  yield node;
  if (!("label" in node)) {
    yield* preorder(node.left);
    yield* preorder(node.right);
  }
}

const days = readRows(process.argv[2]).map((row) => ({
  x: FEATURES.map((name) => Number(row[name])),
  rain: row.rain,
  split: row.split,
}));
const train = days.filter((day) => day.split === "train");
const test = days.filter((day) => day.split === "test");
const tree = grow(train);

console.log(`train_count ${train.length}`);
console.log(`test_count ${test.length}`);
let k = 0;
let leaves = 0;
for (const node of preorder(tree)) {
  k++;
  if ("label" in node) {
    console.log(`node_${k}_predict ${node.label}`);
    leaves++;
  } else {
    console.log(`node_${k}_feature ${FEATURES[node.feature]}`);
    console.log(`node_${k}_threshold ${node.threshold.toFixed(6)}`);
  }
}
console.log(`leaves ${leaves}`);

const countCorrect = (days) => days.filter((day) => predict(tree, day.x) === day.rain).length;
const correct = countCorrect(test);
console.log(`train_accuracy ${(countCorrect(train) / train.length).toFixed(6)}`);
console.log(`correct ${correct}`);
console.log(`accuracy ${(correct / test.length).toFixed(6)}`);
