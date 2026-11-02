// Descriptive statistics on one CSV column, using only Swift's standard
// library and Foundation, which ships with it.
//
// Swift has no mean, median, or variance, so we write them. Foundation reads
// the file and formats the numbers; the arithmetic is plain Swift.

import Foundation

let column = "minutes"

// The named column of a CSV file, as numbers. A function that can fail is
// marked throws, and every call to it is marked try.
func readColumn(_ path: String, _ name: String) throws -> [Double] {
    let text = try String(contentsOfFile: path, encoding: .utf8)
    // split skips empty pieces, so a blank last line doesn't become a row.
    var lines = text.split(separator: "\n")
    let header = lines.removeFirst().split(separator: ",").map(String.init)
    guard let index = header.firstIndex(of: name) else {
        fatalError("no column \(name)")
    }
    // Double(_:) gives nil for text that isn't a number, and ! stops the
    // program there instead of carrying on with a missing value.
    return lines.map { line in
        Double(line.split(separator: ",", omittingEmptySubsequences: false)[index])!
    }
}

let values = try readColumn(CommandLine.arguments[1], column).sorted()
let n = values.count
// Swift never mixes Int and Double on its own; Double(n) converts the count.
let count = Double(n)
let sum = values.reduce(0, +)
let mean = sum / count

// Arrays count from 0: for n = 120 the middle pair is at 59 and 60.
let median = n % 2 == 1
    ? values[n / 2]
    : (values[n / 2 - 1] + values[n / 2]) / 2

// Sample variance divides by n - 1, not n (Bessel's correction).
let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / (count - 1)

func show(_ name: String, _ value: Double) {
    print(name, String(format: "%.6f", value))
}

print("count", n)
show("sum", sum)
show("mean", mean)
show("median", median)
show("min", values.first!)
show("max", values.last!)
show("range", values.last! - values.first!)
show("variance", variance)
show("std_dev", variance.squareRoot())
