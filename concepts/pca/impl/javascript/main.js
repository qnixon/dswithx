// Principal component analysis by power iteration, using only Node's built-in
// modules. Standardizes the four scores, builds their correlation matrix, and
// finds the top two eigenvectors (the principal components): power iteration
// finds the first, then deflation removes it from the matrix so the same steps
// find the second.

import { readFileSync } from "node:fs";

const SUBJECTS = ["math", "physics", "reading", "writing"];
const STEPS = 1000;

// Node has no CSV parser. No field here is quoted, so we split on commas and
// keep the four score columns of each row as numbers.
function readRows(path) {
  const [header, ...lines] = readFileSync(path, "utf8").trim().split("\n");
  const names = header.split(",");
  const indexes = SUBJECTS.map((subject) => names.indexOf(subject));
  return lines.map((line) => {
    const fields = line.split(",");
    return indexes.map((i) => Number(fields[i]));
  });
}

const sum = (numbers) => numbers.reduce((acc, x) => acc + x, 0);
const dot = (u, v) => sum(u.map((a, i) => a * v[i]));
const matVec = (m, v) => m.map((row) => dot(row, v));
const normalize = (v) => {
  const length = Math.sqrt(dot(v, v));
  return v.map((x) => x / length);
};

// Power iteration: multiply by the matrix and rescale, STEPS times.
// Returns the eigenvalue and the eigenvector.
function topEigenvector(m) {
  let v = m.map((_, i) => (i === 0 ? 1 : 0));
  for (let step = 0; step < STEPS; step++) {
    v = normalize(matVec(m, v));
  }
  // An eigenvector can point either way; make its first entry positive.
  if (v[0] < 0) v = v.map((x) => -x);
  return [dot(v, matVec(m, v)), v];
}

const rows = readRows(process.argv[2]);
const n = rows.length;
const k = SUBJECTS.length;
const indices = SUBJECTS.map((_, j) => j);

// Standardize each column to mean 0 and (sample) standard deviation 1.
const means = indices.map((j) => sum(rows.map((row) => row[j])) / n);
const sds = indices.map((j) =>
  Math.sqrt(sum(rows.map((row) => (row[j] - means[j]) ** 2)) / (n - 1)),
);
const z = rows.map((row) => row.map((x, j) => (x - means[j]) / sds[j]));

// The correlation matrix: the covariance of the standardized columns.
const corr = indices.map((i) => indices.map((j) => sum(z.map((r) => r[i] * r[j])) / (n - 1)));

const [value1, pc1] = topEigenvector(corr);
// Deflation: subtract the first component's share, leaving the rest.
const deflated = corr.map((row, i) => row.map((x, j) => x - value1 * pc1[i] * pc1[j]));
const [value2, pc2] = topEigenvector(deflated);

// Prints one component: its eigenvalue, share of the variance, and loadings.
function report(c, value, pc) {
  console.log(`eigenvalue_${c} ${value.toFixed(6)}`);
  // Standardized columns each have variance 1, so the total is k.
  console.log(`explained_${c} ${(value / k).toFixed(6)}`);
  SUBJECTS.forEach((subject, j) => console.log(`pc${c}_${subject} ${pc[j].toFixed(6)}`));
}

console.log(`count ${n}`);
report(1, value1, pc1);
report(2, value2, pc2);
console.log(`student_1_pc1 ${dot(z[0], pc1).toFixed(6)}`);
console.log(`student_1_pc2 ${dot(z[0], pc2).toFixed(6)}`);
