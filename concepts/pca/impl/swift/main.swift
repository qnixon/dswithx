// Principal component analysis by power iteration, using only Swift's
// standard library and Foundation, which ships with it.
//
// Standardizes the four scores, builds their correlation matrix, and finds
// the top two eigenvectors (the principal components): power iteration finds
// the first, then deflation removes it from the matrix so the same steps find
// the second.

import Foundation

let subjects = ["math", "physics", "reading", "writing"]
let k = subjects.count
let steps = 1000

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

// Swift has no matrix type: a matrix is an array of rows, [[Double]].
// Arrays are values, so assigning one copies it.
func dot(_ u: [Double], _ v: [Double]) -> Double {
    zip(u, v).map { $0 * $1 }.reduce(0, +)
}

func matVec(_ m: [[Double]], _ v: [Double]) -> [Double] {
    m.map { row in dot(row, v) }
}

func normalize(_ v: [Double]) -> [Double] {
    let length = dot(v, v).squareRoot()
    return v.map { $0 / length }
}

// Power iteration: multiply by the matrix and rescale, steps times.
// Returns the eigenvalue and the eigenvector as a named pair (a tuple).
func topEigenvector(_ m: [[Double]]) -> (value: Double, vector: [Double]) {
    var v = [Double](repeating: 0, count: k)
    v[0] = 1
    for _ in 0..<steps {
        v = normalize(matVec(m, v))
    }
    // An eigenvector can point either way; make its first entry positive.
    if v[0] < 0 {
        v = v.map { -$0 }
    }
    return (dot(v, matVec(m, v)), v)
}

let path = CommandLine.arguments[1]
let columns = try subjects.map { try readColumn(path, $0) }
let n = columns[0].count
let count = Double(n)

// Standardize each column to mean 0 and (sample) standard deviation 1.
let z = columns.map { column in
    let mean = column.reduce(0, +) / count
    let squares = column.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
    let sd = (squares / (count - 1)).squareRoot()
    return column.map { ($0 - mean) / sd }
}

// The correlation matrix: the covariance of the standardized columns.
let corr = (0..<k).map { i in
    (0..<k).map { j in dot(z[i], z[j]) / (count - 1) }
}

let first = topEigenvector(corr)
// Deflation: subtract the first component's share, leaving the rest.
var deflated = corr
for i in 0..<k {
    for j in 0..<k {
        deflated[i][j] -= first.value * first.vector[i] * first.vector[j]
    }
}
let second = topEigenvector(deflated)

func show(_ name: String, _ value: Double) {
    print(name, String(format: "%.6f", value))
}

print("count", n)
for (c, pc) in [first, second].enumerated() {
    show("eigenvalue_\(c + 1)", pc.value)
    // Standardized columns each have variance 1, so the total is k.
    show("explained_\(c + 1)", pc.value / Double(k))
    for (subject, loading) in zip(subjects, pc.vector) {
        show("pc\(c + 1)_\(subject)", loading)
    }
}
// The first student's standardized scores, one from each column.
let student = z.map { $0[0] }
show("student_1_pc1", dot(student, first.vector))
show("student_1_pc2", dot(student, second.vector))
