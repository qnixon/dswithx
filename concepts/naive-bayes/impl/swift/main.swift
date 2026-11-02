// Categorical naive Bayes with add-one (Laplace) smoothing, using only Swift's
// standard library and Foundation, which ships with it.
//
// Learns P(label) and P(feature value | label) by counting training rows, then
// labels each test row with the label that has the highest log-probability.

import Foundation

let features = ["has_link", "mentions_money", "known_sender"]

// The named column of a CSV file, as text. A function that can fail is
// marked throws, and every call to it is marked try.
func readColumn(_ path: String, _ name: String) throws -> [String] {
    let text = try String(contentsOfFile: path, encoding: .utf8)
    // split skips empty pieces, so a blank last line doesn't become a row.
    var lines = text.split(separator: "\n")
    let header = lines.removeFirst().split(separator: ",").map(String.init)
    guard let index = header.firstIndex(of: name) else {
        fatalError("no column \(name)")
    }
    return lines.map { line in
        String(line.split(separator: ",", omittingEmptySubsequences: false)[index])
    }
}

// A dictionary key must be Hashable. Declaring it is enough: Swift writes the
// hashing and == for a struct whose fields are all Hashable.
struct CountKey: Hashable {
    let feature: String
    let value: String
    let label: String
}

let path = CommandLine.arguments[1]
let split = try readColumn(path, "split")
let labels = try readColumn(path, "label")
// columns["has_link"] is that whole column, one entry per row.
var columns: [String: [String]] = [:]
for f in features {
    columns[f] = try readColumn(path, f)
}

let trainRows = split.indices.filter { split[$0] == "train" }
let testRows = split.indices.filter { split[$0] == "test" }

// Looking up a missing key gives nil; [key, default: 0] gives 0 instead,
// so += 1 starts a new count at zero.
var labelCounts: [String: Int] = [:]
var valueCounts: [CountKey: Int] = [:]
for i in trainRows {
    labelCounts[labels[i], default: 0] += 1
    for f in features {
        valueCounts[CountKey(feature: f, value: columns[f]![i], label: labels[i]), default: 0] += 1
    }
}
// A Set keeps one copy of each value, so its count is the number of distinct values.
var distinctValues: [String: Int] = [:]
for f in features {
    distinctValues[f] = Set(trainRows.map { columns[f]![$0] }).count
}

func logScore(_ row: Int, _ label: String) -> Double {
    // Logs turn the product of probabilities into a sum, avoiding underflow.
    let nLabel = Double(labelCounts[label]!)
    var score = log(nLabel / Double(trainRows.count))
    for f in features {
        // Add-one smoothing: an unseen value never gets probability zero.
        let key = CountKey(feature: f, value: columns[f]![row], label: label)
        let count = Double(valueCounts[key, default: 0] + 1)
        score += log(count / (nLabel + Double(distinctValues[f]!)))
    }
    return score
}

// A dictionary's order isn't sorted and can change from run to run, so we
// sort the labels. Only a strictly higher score replaces the best, so an
// exact tie goes to the alphabetically first label.
let sortedLabels = labelCounts.keys.sorted()
func classify(_ row: Int) -> String {
    var best = sortedLabels[0]
    for label in sortedLabels.dropFirst() where logScore(row, label) > logScore(row, best) {
        best = label
    }
    return best
}

let correct = testRows.filter { classify($0) == labels[$0] }.count

print("train_count", trainRows.count)
print("test_count", testRows.count)
print("correct", correct)
print("accuracy", String(format: "%.6f", Double(correct) / Double(testRows.count)))
