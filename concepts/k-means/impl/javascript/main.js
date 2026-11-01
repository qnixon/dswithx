// k-means clustering (Lloyd's algorithm), using only Node's built-in modules.
// Starts from the first K points as centroids, then alternates two steps until
// no point changes cluster: assign each point to its nearest centroid, and move
// each centroid to the mean of its points.

import { readFileSync } from "node:fs";

const K = 3;
const MAX_ITERATIONS = 100;

// Node has no CSV parser. No field here is quoted, so we split on commas and
// find the x and y columns by their header names.
function readPoints(path) {
  const [header, ...lines] = readFileSync(path, "utf8").trim().split("\n");
  const names = header.split(",");
  const ix = names.indexOf("x");
  const iy = names.indexOf("y");
  return lines.map((line) => {
    const fields = line.split(",");
    return [Number(fields[ix]), Number(fields[iy])];
  });
}

function distance([x1, y1], [x2, y2]) {
  return Math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2);
}

function nearest(point, centroids) {
  // Only a strictly smaller distance replaces the best so far, so ties go to
  // the lower index.
  let best = 0;
  for (let j = 1; j < centroids.length; j++) {
    if (distance(point, centroids[j]) < distance(point, centroids[best])) best = j;
  }
  return best;
}

// == on two arrays compares identity, not contents, so compare element by element.
const sameAssignment = (a, b) => b !== null && a.every((cluster, i) => cluster === b[i]);

const points = readPoints(process.argv[2]);
const centroids = points.slice(0, K).map(([x, y]) => [x, y]);
let assignment = null;
let iterations = 0;
while (iterations < MAX_ITERATIONS) {
  iterations++;
  const newAssignment = points.map((p) => nearest(p, centroids));
  if (sameAssignment(newAssignment, assignment)) break;
  assignment = newAssignment;
  for (let j = 0; j < K; j++) {
    const members = points.filter((_, i) => assignment[i] === j);
    if (members.length > 0) {
      // An empty cluster keeps its old centroid.
      const sumX = members.reduce((acc, [x]) => acc + x, 0);
      const sumY = members.reduce((acc, [, y]) => acc + y, 0);
      centroids[j] = [sumX / members.length, sumY / members.length];
    }
  }
}

const sizes = centroids.map((_, j) => assignment.filter((a) => a === j).length);
const inertia = points.reduce((acc, p, i) => acc + distance(p, centroids[assignment[i]]) ** 2, 0);

console.log(`iterations ${iterations}`);
centroids.forEach(([x, y], j) => {
  console.log(`centroid_${j + 1}_x ${x.toFixed(6)}`);
  console.log(`centroid_${j + 1}_y ${y.toFixed(6)}`);
});
sizes.forEach((size, j) => console.log(`size_${j + 1} ${size}`));
console.log(`inertia ${inertia.toFixed(6)}`);
