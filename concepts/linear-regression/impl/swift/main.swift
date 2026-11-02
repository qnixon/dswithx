// Simple linear regression by least squares, using only Swift's standard
// library and Foundation, which ships with it.
//
// Fits score = intercept + slope * hours. Swift has no regression or
// correlation function, so the sums are written out; Foundation reads the
// file and formats the numbers.

import Foundation

let xColumn = "hours"
let yColumn = "score"

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

let path = CommandLine.arguments[1]
let xs = try readColumn(path, xColumn)
let ys = try readColumn(path, yColumn)

// First pass: the means. Double(xs.count) converts the Int count, since
// Swift never mixes Int and Double on its own.
let n = Double(xs.count)
let meanX = xs.reduce(0, +) / n
let meanY = ys.reduce(0, +) / n

// Second pass: sums of squared deviations and of cross-products. zip pairs
// each hours value with the score from the same row.
let sxx = xs.map { ($0 - meanX) * ($0 - meanX) }.reduce(0, +)
let syy = ys.map { ($0 - meanY) * ($0 - meanY) }.reduce(0, +)
let sxy = zip(xs, ys).map { x, y in (x - meanX) * (y - meanY) }.reduce(0, +)

let slope = sxy / sxx
let intercept = meanY - slope * meanX
let r = sxy / (sxx * syy).squareRoot()

func show(_ name: String, _ value: Double) {
    print(name, String(format: "%.6f", value))
}

print("count", xs.count)
show("slope", slope)
show("intercept", intercept)
show("r", r)
show("r_squared", r * r)
