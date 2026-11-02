// k-means clustering (Lloyd's algorithm), using only Swift's standard library
// and Foundation, which ships with it.
//
// Starts from the first k points as centroids, then alternates two steps until
// no point changes cluster: assign each point to its nearest centroid, and
// move each centroid to the mean of its points.

import Foundation

let k = 3
let maxIterations = 100

// A struct is a value type: copying a Point copies both numbers.
struct Point {
    var x: Double
    var y: Double
}

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

func squaredDistance(_ a: Point, _ b: Point) -> Double {
    (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
}

// The index of the nearest centroid. A strict < keeps the first of equal
// distances, so a tie goes to the lower index.
func nearest(_ point: Point, _ centroids: [Point]) -> Int {
    var best = 0
    for j in 1..<centroids.count
    where squaredDistance(point, centroids[j]) < squaredDistance(point, centroids[best]) {
        best = j
    }
    return best
}

let path = CommandLine.arguments[1]
let xs = try readColumn(path, "x")
let ys = try readColumn(path, "y")
// zip pairs the two columns row by row.
let points = zip(xs, ys).map { Point(x: $0, y: $1) }

var centroids = Array(points.prefix(k))
// An empty array stands for "no assignment yet"; a real one has 150 entries.
var assignment: [Int] = []
var iterations = 0
while iterations < maxIterations {
    iterations += 1
    let newAssignment = points.map { nearest($0, centroids) }
    // == on arrays compares every element, so this asks whether any point moved.
    if newAssignment == assignment {
        break // this unchanged pass still counts
    }
    for j in 0..<k {
        let members = zip(points, newAssignment).filter { $0.1 == j }.map { $0.0 }
        // An empty cluster keeps its old centroid.
        if !members.isEmpty {
            let n = Double(members.count)
            centroids[j] = Point(x: members.map(\.x).reduce(0, +) / n,
                                 y: members.map(\.y).reduce(0, +) / n)
        }
    }
    assignment = newAssignment
}

let inertia = zip(points, assignment)
    .map { squaredDistance($0.0, centroids[$0.1]) }
    .reduce(0, +)

func show(_ name: String, _ value: Double) {
    print(name, String(format: "%.6f", value))
}

print("iterations", iterations)
for (j, c) in centroids.enumerated() {
    show("centroid_\(j + 1)_x", c.x)
    show("centroid_\(j + 1)_y", c.y)
}
for j in 0..<k {
    print("size_\(j + 1)", assignment.filter { $0 == j }.count)
}
show("inertia", inertia)
