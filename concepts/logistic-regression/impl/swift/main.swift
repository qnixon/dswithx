// Logistic regression by gradient descent, using only Swift's standard
// library and Foundation, which ships with it.
//
// Predicts whether a student passed from study hours and sleep. Each feature
// is rescaled with the training rows' mean and standard deviation, then the
// weights start at zero and take 1000 fixed steps of batch gradient descent
// on the average log-loss.

import Foundation

let learningRate = 0.5
let steps = 1000

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

// Double(_:) gives nil for text that isn't a number, and ! stops the
// program there instead of carrying on with a missing value.
func readNumbers(_ path: String, _ name: String) throws -> [Double] {
    try readColumn(path, name).map { Double($0)! }
}

func sigmoid(_ z: Double) -> Double {
    1 / (1 + exp(-z))
}

func dot(_ u: [Double], _ v: [Double]) -> Double {
    zip(u, v).map { $0 * $1 }.reduce(0, +)
}

func mean(_ xs: [Double]) -> Double {
    xs.reduce(0, +) / Double(xs.count)
}

// Sample standard deviation: divide by n - 1.
func sd(_ xs: [Double]) -> Double {
    let m = mean(xs)
    let squares = xs.map { ($0 - m) * ($0 - m) }.reduce(0, +)
    return (squares / Double(xs.count - 1)).squareRoot()
}

let path = CommandLine.arguments[1]
let hours = try readNumbers(path, "hours")
let sleep = try readNumbers(path, "sleep")
let passed = try readNumbers(path, "passed")
let split = try readColumn(path, "split")

// indices is 0..<200; filter keeps the row numbers of each split.
let trainRows = split.indices.filter { split[$0] == "train" }
let testRows = split.indices.filter { split[$0] == "test" }

// Scale with the training rows only. The means and sds are [hours, sleep].
let features = [hours, sleep]
let means = features.map { column in mean(trainRows.map { column[$0] }) }
let sds = features.map { column in sd(trainRows.map { column[$0] }) }

// One scaled row: a leading 1 for the intercept, then each feature.
func scaled(_ row: Int) -> [Double] {
    [1] + (0..<2).map { j in (features[j][row] - means[j]) / sds[j] }
}

let xs = trainRows.map(scaled)
let ys = trainRows.map { passed[$0] }
let n = Double(xs.count)

var weights = [0.0, 0.0, 0.0]
for _ in 0..<steps {
    // Gradient of the average log-loss: the mean of (p - y) times each
    // input, computed in full before any weight changes.
    let errors = zip(xs, ys).map { x, y in sigmoid(dot(weights, x)) - y }
    let gradient = (0..<3).map { j in
        zip(errors, xs).map { e, x in e * x[j] }.reduce(0, +) / n
    }
    // A new array of weights replaces the old one.
    weights = zip(weights, gradient).map { w, g in w - learningRate * g }
}

let logLoss = -zip(xs, ys).map { x, y in
    let p = sigmoid(dot(weights, x))
    return y * log(p) + (1 - y) * log(1 - p)
}.reduce(0, +) / n

let correct = testRows.filter { row in
    let predicted = sigmoid(dot(weights, scaled(row))) >= 0.5 ? 1.0 : 0.0
    return predicted == passed[row]
}.count

func show(_ name: String, _ value: Double) {
    print(name, String(format: "%.6f", value))
}

print("train_count", trainRows.count)
print("test_count", testRows.count)
show("intercept", weights[0])
show("weight_hours", weights[1])
show("weight_sleep", weights[2])
show("log_loss", logLoss)
print("correct", correct)
show("accuracy", Double(correct) / Double(testRows.count))
