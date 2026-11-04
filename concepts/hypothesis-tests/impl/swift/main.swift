// Exact two-sided permutation test for a difference in means, using only
// Swift's standard library and Foundation, which ships with it.
//
// If compost made no difference, the "compost" and "control" labels are
// arbitrary, and any 8 of the 16 plants could have carried the compost label.
// We try every one of those splits and count how many give a difference at
// least as large as the one we observed. That fraction is the p-value.

import Foundation

// Read group,grams lines. split skips empty pieces, so a blank last line
// doesn't become a row. Int(_:) gives an optional, which ! unwraps.
let text = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
var control: [Int] = []
var compost: [Int] = []
for line in text.split(separator: "\n").dropFirst() {  // dropFirst skips the header
    let fields = line.split(separator: ",")
    let grams = Int(fields[1])!
    if fields[0] == "compost" {
        compost.append(grams)
    } else {
        control.append(grams)
    }
}
let n = compost.count
precondition(n > 0 && control.count == n, "need two groups of equal size")

let plants = control + compost
let total = plants.reduce(0, +)

// Both groups have the same size, so comparing totals is the same as
// comparing means, and totals stay whole numbers: no floating-point near-ties.
let observed = compost.reduce(0, +) - control.reduce(0, +)

// Each whole number from 0 to 2^16 - 1 is a mask: bit i set means plant i is
// labeled compost. nonzeroBitCount counts the set bits, so the masks with
// exactly n of them are the splits.
var splits = 0
var asExtreme = 0
for mask in 0..<(1 << plants.count) where mask.nonzeroBitCount == n {
    var chosen = 0
    for i in plants.indices where mask & (1 << i) != 0 {
        chosen += plants[i]
    }
    let difference = chosen - (total - chosen)
    splits += 1
    if abs(difference) >= abs(observed) {  // two-sided
        asExtreme += 1
    }
}

func six(_ x: Double) -> String { String(format: "%.6f", x) }
print("control_count", control.count)
print("compost_count", n)
print("control_mean", six(Double(control.reduce(0, +)) / Double(n)))
print("compost_mean", six(Double(compost.reduce(0, +)) / Double(n)))
print("observed_difference", six(Double(observed) / Double(n)))
print("splits", splits)
print("as_extreme", asExtreme)
print("p_value", six(Double(asExtreme) / Double(splits)))
