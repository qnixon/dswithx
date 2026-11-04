// 5-fold cross-validation for k-nearest neighbors, using only Node's built-in
// modules. Scores each odd k from 1 to 15 by holding out one fold of the
// training seeds at a time, picks the best k, and then scores that k once on
// the untouched test seeds.

import { readFileSync } from "node:fs";

const FOLDS = 5;
const KS = [1, 3, 5, 7, 9, 11, 13, 15]; // odd k only, so two varieties can't tie
const FEATURES = ["length_mm", "width_mm"];
const LABEL = "variety";

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

function distance(a, b) {
  return Math.sqrt(a.reduce((acc, x, i) => acc + (x - b[i]) ** 2, 0));
}

function classify(point, train, k) {
  // Array.prototype.sort is stable (guaranteed since ES2019), so seeds at an
  // equal distance keep file order. toSorted() returns a sorted copy.
  const nearest = train
    .map((seed) => ({ label: seed.label, dist: distance(point, seed.features) }))
    .toSorted((a, b) => a.dist - b.dist)
    .slice(0, k);

  // A Map keeps insertion order, and we keep the first label to reach the
  // top count, so a tied vote goes to the label seen first among the nearest.
  const votes = new Map();
  for (const { label } of nearest) votes.set(label, (votes.get(label) ?? 0) + 1);
  let best = null;
  for (const [label, count] of votes) {
    if (best === null || count > votes.get(best)) best = label;
  }
  return best;
}

function countCorrect(points, train, k) {
  return points.filter((seed) => classify(seed.features, train, k) === seed.label).length;
}

function cvAccuracy(train, k) {
  // Fold f is rows f * size up to (f + 1) * size. The rows are already
  // shuffled, so consecutive blocks make fair folds. slice(start, end) copies
  // rows start to end - 1; with one argument it runs to the end.
  const size = Math.floor(train.length / FOLDS);
  let correct = 0;
  for (let f = 0; f < FOLDS; f++) {
    const heldOut = train.slice(f * size, (f + 1) * size);
    const rest = [...train.slice(0, f * size), ...train.slice((f + 1) * size)];
    correct += countCorrect(heldOut, rest, k);
  }
  return correct / train.length;
}

const seeds = readRows(process.argv[2]).map((row) => ({
  features: FEATURES.map((name) => Number(row[name])),
  label: row[LABEL],
  split: row.split,
}));
const train = seeds.filter((seed) => seed.split === "train");
const test = seeds.filter((seed) => seed.split === "test");

console.log(`train_count ${train.length}`);
console.log(`test_count ${test.length}`);
let bestK = null;
let bestAccuracy = -1;
for (const k of KS) {
  const accuracy = cvAccuracy(train, k);
  console.log(`cv_accuracy_k${k} ${accuracy.toFixed(6)}`);
  // Strictly better, so ties keep the smaller k.
  if (accuracy > bestAccuracy) [bestK, bestAccuracy] = [k, accuracy];
}

// Only now touch the test seeds, once, with the chosen k and all of train.
const correct = countCorrect(test, train, bestK);
console.log(`best_k ${bestK}`);
console.log(`test_correct ${correct}`);
console.log(`test_accuracy ${(correct / test.length).toFixed(6)}`);
