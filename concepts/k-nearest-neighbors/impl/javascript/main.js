// k-nearest neighbors classification, using only Node's built-in modules.
// Each test seed is labelled with the majority variety among its K nearest
// training seeds, by Euclidean distance.

import { readFileSync } from "node:fs";

const K = 5;
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

function classify(point, train) {
  // Array.prototype.sort is stable (guaranteed since ES2019), so seeds at an
  // equal distance keep file order. toSorted() returns a sorted copy.
  const nearest = train
    .map((seed) => ({ label: seed.label, dist: distance(point, seed.features) }))
    .toSorted((a, b) => a.dist - b.dist)
    .slice(0, K);

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

const seeds = readRows(process.argv[2]).map((row) => ({
  features: FEATURES.map((name) => Number(row[name])),
  label: row[LABEL],
  split: row.split,
}));
const train = seeds.filter((seed) => seed.split === "train");
const test = seeds.filter((seed) => seed.split === "test");

const correct = test.filter((seed) => classify(seed.features, train) === seed.label).length;

console.log(`train_count ${train.length}`);
console.log(`test_count ${test.length}`);
console.log(`correct ${correct}`);
console.log(`accuracy ${(correct / test.length).toFixed(6)}`);
