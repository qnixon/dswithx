// Train and test error for polynomials of degree 1 to 8, using only Swift's
// standard library and Foundation, which ships with it.
//
// Each polynomial is fitted by least squares to the training drives only: we
// build the normal equations and solve them by Gaussian elimination. Then we
// measure its root-mean-square error on the training drives and on the test
// drives it never saw.

import Foundation

let maxDegree = 8

func six(_ x: Double) -> String { String(format: "%.6f", x) }

// Read speed,litres,split lines into two lists of (x, y) tuples, finding each
// column by name. split skips empty pieces, so a blank last line doesn't
// become a row. Double(_:) gives an optional, which ! unwraps.
typealias Point = (x: Double, y: Double)
let text = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
var lines = text.split(separator: "\n")
let header = lines.removeFirst().split(separator: ",").map(String.init)
let speedCol = header.firstIndex(of: "speed")!
let litresCol = header.firstIndex(of: "litres")!
let splitCol = header.firstIndex(of: "split")!
var train: [Point] = []
var test: [Point] = []
for line in lines {
    let fields = line.split(separator: ",")
    let point = (x: Double(fields[speedCol])!, y: Double(fields[litresCol])!)
    if fields[splitCol] == "train" {
        train.append(point)
    } else {
        test.append(point)
    }
}

// Solve a x = b by Gaussian elimination with partial pivoting. Arrays are
// values in Swift, so m is our own copy and changing it leaves a alone.
func solve(_ a: [[Double]], _ b: [Double]) -> [Double] {
    let n = b.count
    var m = (0..<n).map { a[$0] + [b[$0]] }  // augmented matrix
    for col in 0..<n {
        // Swap up the row with the largest entry in this column, which keeps
        // the rounding error small.
        let pivot = (col..<n).max { abs(m[$0][col]) < abs(m[$1][col]) }!
        m.swapAt(col, pivot)
        for r in (col + 1)..<n {
            let factor = m[r][col] / m[col][col]
            for c in col...n {
                m[r][c] -= factor * m[col][c]
            }
        }
    }
    // Back substitution, from the last unknown up.
    var x = [Double](repeating: 0, count: n)
    for r in (0..<n).reversed() {
        var s = m[r][n]
        for c in (r + 1)..<n {
            s -= m[r][c] * x[c]
        }
        x[r] = s / m[r][r]
    }
    return x
}

// Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
// Z is 1, z_i, z_i^2, ..., z_i^degree.
func fit(_ points: [Point], _ degree: Int, _ scale: (Double) -> Double) -> [Double] {
    let size = degree + 1
    var a = [[Double]](repeating: [Double](repeating: 0, count: size), count: size)
    var b = [Double](repeating: 0, count: size)
    for p in points {
        let z = scale(p.x)
        for i in 0..<size {
            b[i] += p.y * pow(z, Double(i))
            for j in 0..<size {
                a[i][j] += pow(z, Double(i + j))
            }
        }
    }
    return solve(a, b)
}

func rmse(_ coefs: [Double], _ points: [Point], _ scale: (Double) -> Double) -> Double {
    var total = 0.0
    for p in points {
        let z = scale(p.x)
        var predicted = 0.0
        for (i, c) in coefs.enumerated() {
            predicted += c * pow(z, Double(i))
        }
        total += (predicted - p.y) * (predicted - p.y)
    }
    return (total / Double(points.count)).squareRoot()
}

// Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
// largest entry at degree 8) would swamp the small ones and make the
// equations hard to solve accurately.
let low = train.map { $0.x }.min()!
let high = train.map { $0.x }.max()!
let mid = (low + high) / 2
let half = (high - low) / 2
func scale(_ x: Double) -> Double { (x - mid) / half }

print("train_count", train.count)
print("test_count", test.count)
var errors: [(train: Double, test: Double)] = []
for degree in 1...maxDegree {
    let coefs = fit(train, degree, scale)
    errors.append((train: rmse(coefs, train, scale), test: rmse(coefs, test, scale)))
}
for (i, e) in errors.enumerated() {
    print("train_rmse_d\(i + 1)", six(e.train))
}
for (i, e) in errors.enumerated() {
    print("test_rmse_d\(i + 1)", six(e.test))
}
