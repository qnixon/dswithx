// Categorical naive Bayes with add-one (Laplace) smoothing, Node built-ins only.
// Learns P(label) and P(feature value | label) by counting training rows, then
// labels each test row with the label that has the highest log-probability.

import { readFileSync } from "node:fs";

const FEATURES = ["has_link", "mentions_money", "known_sender"];
const LABEL = "label";

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

// A Map counter. Arrays compare by identity, so a key made of several parts
// is joined into one string: "has_link|yes|spam".
function countBy(items, keyOf) {
  const counts = new Map();
  for (const item of items) {
    const key = keyOf(item);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return counts;
}

const rows = readRows(process.argv[2]);
const train = rows.filter((row) => row.split === "train");
const test = rows.filter((row) => row.split === "test");

const labelCounts = countBy(train, (row) => row[LABEL]);
// valueCounts.get("feature|value|label") = number of training rows
const valueCounts = countBy(
  train.flatMap((row) => FEATURES.map((f) => [f, row[f], row[LABEL]])),
  (parts) => parts.join("|"),
);
const distinctValues = Object.fromEntries(
  FEATURES.map((f) => [f, new Set(train.map((row) => row[f])).size]),
);

function logScore(row, label) {
  // Logs turn the product of probabilities into a sum, avoiding underflow.
  let score = Math.log(labelCounts.get(label) / train.length);
  for (const f of FEATURES) {
    // Add-one smoothing: an unseen value never gets probability zero.
    const count = (valueCounts.get([f, row[f], label].join("|")) ?? 0) + 1;
    score += Math.log(count / (labelCounts.get(label) + distinctValues[f]));
  }
  return score;
}

// Labels are tried in alphabetical order and only a strictly higher score
// replaces the best, so an exact tie goes to the alphabetically first label.
const labels = [...labelCounts.keys()].sort();
function classify(row) {
  let best = labels[0];
  for (const label of labels.slice(1)) {
    if (logScore(row, label) > logScore(row, best)) best = label;
  }
  return best;
}

const correct = test.filter((row) => classify(row) === row[LABEL]).length;

console.log(`train_count ${train.length}`);
console.log(`test_count ${test.length}`);
console.log(`correct ${correct}`);
console.log(`accuracy ${(correct / test.length).toFixed(6)}`);
