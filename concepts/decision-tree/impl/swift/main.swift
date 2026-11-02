// A decision tree classifier (CART with Gini impurity), using only Swift's
// standard library and Foundation, which ships with it.
//
// Grows a tree on the training days by always making the split that leaves
// the two sides purest, then predicts rain for the test days. Prints the tree
// in preorder: each node is either a split (feature and threshold) or a leaf
// (its prediction).

import Foundation

let features = ["humidity", "pressure", "wind"]
let maxDepth = 3
let minSize = 5

struct Day {
    let x: [Double]
    let rain: Bool
}

// A node is exactly one of two things, and the enum says so. A case that
// holds a Node inside a Node must be marked indirect, which tells Swift to
// keep the children behind a reference it manages for us.
indirect enum Node {
    case leaf(Bool)
    case split(feature: Int, threshold: Double, left: Node, right: Node)
}

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

func countYes(_ days: [Day]) -> Int {
    days.filter { $0.rain }.count
}

// Chance that two days drawn at random (with replacement) disagree.
func gini(_ days: [Day]) -> Double {
    let p = Double(countYes(days)) / Double(days.count)
    return 1 - p * p - (1 - p) * (1 - p)
}

// Rain only on a strict majority; an even split predicts no rain.
func majority(_ days: [Day]) -> Bool {
    2 * countYes(days) > days.count
}

// The (score, feature, threshold) with the lowest weighted Gini impurity, or
// nil if no feature has two distinct values. Features are tried in column
// order and thresholds from smallest to largest; only a strictly lower score
// replaces the best so far.
func bestSplit(_ days: [Day]) -> (score: Double, feature: Int, threshold: Double)? {
    var best: (score: Double, feature: Int, threshold: Double)? = nil
    for f in features.indices {
        // A Set keeps one copy of each value; sorted() turns it into an array.
        let values = Set(days.map { $0.x[f] }).sorted()
        for (a, b) in zip(values, values.dropFirst()) {
            let threshold = (a + b) / 2
            let left = days.filter { $0.x[f] <= threshold }
            let right = days.filter { $0.x[f] > threshold }
            let score = (Double(left.count) * gini(left) + Double(right.count) * gini(right))
                / Double(days.count)
            // best?.score is nil while best is nil, and ?? supplies infinity.
            if score < (best?.score ?? .infinity) {
                best = (score, f, threshold)
            }
        }
    }
    return best
}

func grow(_ days: [Day], depth: Int = 0) -> Node {
    let impurity = gini(days)
    if impurity == 0 || days.count < minSize || depth == maxDepth {
        return .leaf(majority(days))
    }
    // guard let unwraps the optional, or leaves the function if it can't.
    guard let best = bestSplit(days), best.score < impurity else {
        return .leaf(majority(days)) // no split makes the sides purer
    }
    let left = days.filter { $0.x[best.feature] <= best.threshold }
    let right = days.filter { $0.x[best.feature] > best.threshold }
    return .split(feature: best.feature, threshold: best.threshold,
                  left: grow(left, depth: depth + 1),
                  right: grow(right, depth: depth + 1))
}

// A switch on an enum must cover every case, or it won't compile.
func predict(_ node: Node, _ x: [Double]) -> Bool {
    switch node {
    case .leaf(let rain):
        return rain
    case .split(let feature, let threshold, let left, let right):
        return predict(x[feature] <= threshold ? left : right, x)
    }
}

// Every node, parents before children, left subtree before right.
func preorder(_ node: Node) -> [Node] {
    switch node {
    case .leaf:
        return [node]
    case .split(_, _, let left, let right):
        return [node] + preorder(left) + preorder(right)
    }
}

let path = CommandLine.arguments[1]
let columns = try features.map { try readColumn(path, $0).map { Double($0)! } }
let rain = try readColumn(path, "rain")
let split = try readColumn(path, "split")

var train: [Day] = []
var test: [Day] = []
for i in rain.indices {
    let day = Day(x: columns.map { $0[i] }, rain: rain[i] == "yes")
    if split[i] == "train" { train.append(day) } else { test.append(day) }
}

let tree = grow(train)

print("train_count", train.count)
print("test_count", test.count)
var leaves = 0
for (i, node) in preorder(tree).enumerated() {
    let k = i + 1
    switch node {
    case .leaf(let rain):
        print("node_\(k)_predict", rain ? "yes" : "no")
        leaves += 1
    case .split(let feature, let threshold, _, _):
        print("node_\(k)_feature", features[feature])
        print("node_\(k)_threshold", String(format: "%.6f", threshold))
    }
}
print("leaves", leaves)

func correct(_ days: [Day]) -> Int {
    days.filter { predict(tree, $0.x) == $0.rain }.count
}

print("train_accuracy", String(format: "%.6f", Double(correct(train)) / Double(train.count)))
print("correct", correct(test))
print("accuracy", String(format: "%.6f", Double(correct(test)) / Double(test.count)))
