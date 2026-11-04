// Exact two-sided permutation test for a difference in means, using only
// Node's built-in modules.
//
// If compost made no difference, the "compost" and "control" labels are
// arbitrary, and any 8 of the 16 plants could have carried the compost label.
// We try every one of those splits and count how many give a difference at
// least as large as the one we observed. That fraction is the p-value.

import { readFileSync } from "node:fs";

// Node has no CSV parser. No field here is quoted, so we split on commas.
function read(path) {
  const groups = { control: [], compost: [] };
  const [, ...lines] = readFileSync(path, "utf8").trim().split("\n");
  for (const line of lines) {
    const [group, grams] = line.split(",");
    groups[group].push(Number(grams));
  }
  return [groups.control, groups.compost];
}

const sum = (xs) => xs.reduce((acc, x) => acc + x, 0);

const [control, compost] = read(process.argv[2]);
const n = compost.length;
const plants = [...control, ...compost];
const total = sum(plants);

// Both groups have n plants, so comparing totals is the same as comparing
// means, and totals stay whole numbers: no floating-point near-ties.
const observed = sum(compost) - sum(control);

let splits = 0;
let asExtreme = 0;

// Walk every way to pick `left` more plants from positions start onward,
// carrying the running total of the plants picked so far.
function choose(start, left, chosenTotal) {
  if (left === 0) {
    const difference = chosenTotal - (total - chosenTotal);
    splits++;
    if (Math.abs(difference) >= Math.abs(observed)) asExtreme++; // two-sided
    return;
  }
  // Stop early enough that `left` plants still remain to pick.
  for (let i = start; i <= plants.length - left; i++) {
    choose(i + 1, left - 1, chosenTotal + plants[i]);
  }
}
choose(0, n, 0);

console.log(`control_count ${control.length}`);
console.log(`compost_count ${n}`);
console.log(`control_mean ${(sum(control) / control.length).toFixed(6)}`);
console.log(`compost_mean ${(sum(compost) / n).toFixed(6)}`);
console.log(`observed_difference ${(observed / n).toFixed(6)}`);
console.log(`splits ${splits}`);
console.log(`as_extreme ${asExtreme}`);
console.log(`p_value ${(asExtreme / splits).toFixed(6)}`);
