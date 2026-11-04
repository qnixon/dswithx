// Evaluation metrics for a binary classifier, using only Node's built-in
// modules.
//
// Reads each part's true label and the model's score, then reports the
// confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
// the accuracy of never flagging anything, and the area under the ROC curve.

import { readFileSync } from "node:fs";

const THRESHOLDS = [["50", 0.5], ["30", 0.3]]; // name suffix, threshold

// No field here is quoted, so we split on commas and find columns by name.
function read(path) {
  const [header, ...lines] = readFileSync(path, "utf8").trim().split("\n");
  const columns = header.split(",");
  const iLabel = columns.indexOf("defective");
  const iScore = columns.indexOf("score");
  return lines.map((line) => {
    const fields = line.split(",");
    return { defective: fields[iLabel] === "1", score: Number(fields[iScore]) };
  });
}

function report(parts, suffix, threshold) {
  // A part is flagged when its score reaches the threshold.
  let tp = 0, fp = 0, fn = 0, tn = 0;
  for (const { defective, score } of parts) {
    const flagged = score >= threshold;
    if (flagged && defective) tp++;
    else if (flagged) fp++;
    else if (defective) fn++;
    else tn++;
  }

  const accuracy = (tp + tn) / parts.length;
  const precision = tp / (tp + fp); // of the flagged parts, how many are defective
  const recall = tp / (tp + fn);    // of the defective parts, how many are flagged
  const f1 = (2 * precision * recall) / (precision + recall);

  console.log(`tp_at_${suffix} ${tp}`);
  console.log(`fp_at_${suffix} ${fp}`);
  console.log(`fn_at_${suffix} ${fn}`);
  console.log(`tn_at_${suffix} ${tn}`);
  console.log(`accuracy_at_${suffix} ${accuracy.toFixed(6)}`);
  console.log(`precision_at_${suffix} ${precision.toFixed(6)}`);
  console.log(`recall_at_${suffix} ${recall.toFixed(6)}`);
  console.log(`f1_at_${suffix} ${f1.toFixed(6)}`);
}

// The chance that a random defective part outscores a random good one.
// Compare every pair, scoring 2 for a win and 1 for a tie, so the count
// stays a whole number until the final division.
function auc(parts) {
  const defective = parts.filter((p) => p.defective).map((p) => p.score);
  const good = parts.filter((p) => !p.defective).map((p) => p.score);
  let points = 0;
  for (const d of defective) {
    for (const g of good) {
      if (d > g) points += 2;
      else if (d === g) points += 1;
    }
  }
  return points / (2 * defective.length * good.length);
}

const parts = read(process.argv[2]);
const defective = parts.filter((p) => p.defective).length;

console.log(`parts ${parts.length}`);
console.log(`defective ${defective}`);
// Never flagging anything is right about every good part.
console.log(`baseline_accuracy ${((parts.length - defective) / parts.length).toFixed(6)}`);
for (const [suffix, threshold] of THRESHOLDS) report(parts, suffix, threshold);
console.log(`auc ${auc(parts).toFixed(6)}`);
