// k-nearest neighbors classification, using only Swift's standard library
// and Foundation, which ships with it.
//
// Each test seed is labelled with the majority variety among its k nearest
// training seeds, by Euclidean distance.

import Foundation

let k = 5
let features = ["length_mm", "width_mm"]
let labelColumn = "variety"

// A struct is a value type: copying a Seed copies its fields.
struct Seed {
    let point: [Double]
    let label: String
}

// The rows of a CSV file, each as a dictionary from column name to text.
// A function that can fail is marked throws, and every call to it is marked
// try. The file has no quoted fields, so splitting on commas is enough.
func readRows(_ path: String) throws -> [[String: String]] {
    let text = try String(contentsOfFile: path, encoding: .utf8)
    // split skips empty pieces, so a blank last line doesn't become a row.
    var lines = text.split(separator: "\n")
    let header = lines.removeFirst().split(separator: ",").map(String.init)
    return lines.map { line in
        let fields = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        // zip pairs each column name with its field, and the pairs become a
        // dictionary.
        return Dictionary(uniqueKeysWithValues: zip(header, fields))
    }
}

// Looking up a dictionary key gives an optional, which ! unwraps. Double(_:)
// also gives nil for text that isn't a number, and ! stops the program there.
let rows = try readRows(CommandLine.arguments[1])
func seed(_ row: [String: String]) -> Seed {
    Seed(point: features.map { Double(row[$0]!)! }, label: row[labelColumn]!)
}
let train = rows.filter { $0["split"] == "train" }.map(seed)
let test = rows.filter { $0["split"] == "test" }.map(seed)

func distance(_ a: [Double], _ b: [Double]) -> Double {
    zip(a, b).map { p, q in (p - q) * (p - q) }.reduce(0, +).squareRoot()
}

func classify(_ point: [Double], _ train: [Seed]) -> String {
    // Sort every training seed by distance and keep the first k. Swift's
    // sorted(by:) is stable, so equal distances keep file order.
    let nearest = train
        .sorted { distance(point, $0.point) < distance(point, $1.point) }
        .prefix(k)

    // Count the votes. counts[label, default: 0] reads 0 for a label we
    // haven't seen yet, so += 1 works the first time too.
    var counts: [String: Int] = [:]
    for seed in nearest {
        counts[seed.label, default: 0] += 1
    }

    // A Dictionary has no fixed order, so pick the winner by walking the
    // neighbors nearest first: a tied vote would go to the label met first.
    var winner = nearest.first!.label
    for seed in nearest where counts[seed.label]! > counts[winner]! {
        winner = seed.label
    }
    return winner
}

let correct = test.filter { classify($0.point, train) == $0.label }.count

print("train_count", train.count)
print("test_count", test.count)
print("correct", correct)
print("accuracy", String(format: "%.6f", Double(correct) / Double(test.count)))
