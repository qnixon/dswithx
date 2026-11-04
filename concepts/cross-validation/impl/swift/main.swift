// 5-fold cross-validation for k-nearest neighbors, using only Swift's
// standard library and Foundation, which ships with it.
//
// Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
// holding out one fold at a time, picks the k with the best average
// accuracy, and then scores that k once on the untouched test seeds.

import Foundation

let folds = 5
let ks = stride(from: 1, through: 15, by: 2)  // odd k only, so two varieties can't tie
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

func classify(_ point: [Double], _ train: [Seed], _ k: Int) -> String {
    // Sort every training seed by distance and keep the first k. Swift's
    // sorted(by:) is stable, so equal distances keep file order.
    let nearest = train
        .sorted { distance(point, $0.point) < distance(point, $1.point) }
        .prefix(k)

    // counts[label, default: 0] reads 0 for a label we haven't seen yet.
    var counts: [String: Int] = [:]
    for seed in nearest {
        counts[seed.label, default: 0] += 1
    }

    // A Dictionary has no fixed order, so pick the winner by walking the
    // neighbors nearest first.
    var winner = nearest.first!.label
    for seed in nearest where counts[seed.label]! > counts[winner]! {
        winner = seed.label
    }
    return winner
}

func countCorrect(_ points: [Seed], _ train: [Seed], _ k: Int) -> Int {
    points.filter { classify($0.point, train, k) == $0.label }.count
}

func cvAccuracy(_ train: [Seed], _ k: Int) -> Double {
    // Fold f is rows f*size up to (f+1)*size. The rows are already shuffled,
    // so consecutive blocks make fair folds.
    let size = train.count / folds
    var correct = 0
    for f in 0..<folds {
        let start = f * size, end = (f + 1) * size
        // A range subscript gives an ArraySlice that shares train's storage;
        // Array(...) copies it into an array of its own.
        let heldOut = Array(train[start..<end])
        let rest = Array(train[..<start] + train[end...])
        correct += countCorrect(heldOut, rest, k)
    }
    return Double(correct) / Double(train.count)
}

print("train_count", train.count)
print("test_count", test.count)
var bestK = 0
var bestAccuracy = -1.0
for k in ks {
    let accuracy = cvAccuracy(train, k)
    print("cv_accuracy_k\(k)", String(format: "%.6f", accuracy))
    if accuracy > bestAccuracy {  // strictly better, so ties keep the smaller k
        bestK = k
        bestAccuracy = accuracy
    }
}

// Only now touch the test seeds, once, with the chosen k and all of train.
let correct = countCorrect(test, train, bestK)
print("best_k", bestK)
print("test_correct", correct)
print("test_accuracy", String(format: "%.6f", Double(correct) / Double(test.count)))
