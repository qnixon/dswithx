//! Train and test error for polynomials of degree 1 to 8, using only the
//! standard library.
//!
//! Each polynomial is fitted by least squares to the training drives only:
//! we build the normal equations and solve them by Gaussian elimination.
//! Then we measure its root-mean-square error on the training drives and on
//! the test drives it never saw.

use std::env;
use std::fs;

const MAX_DEGREE: usize = 8;

/// Each drive becomes (speed, litres), sorted into train and test. The file
/// has no quoted fields, so commas suffice; columns are found by name.
fn read(path: &str) -> (Vec<(f64, f64)>, Vec<(f64, f64)>) {
    let text = fs::read_to_string(path).expect("cannot read data file");
    let mut lines = text.lines();
    let columns: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    let column = |name| columns.iter().position(|&c| c == name).expect("missing column");
    let (i_speed, i_litres, i_split) = (column("speed"), column("litres"), column("split"));
    let (mut train, mut test) = (Vec::new(), Vec::new());
    for line in lines {
        let fields: Vec<&str> = line.split(',').collect();
        let speed: f64 = fields[i_speed].parse().expect("speed must be a number");
        let litres: f64 = fields[i_litres].parse().expect("litres must be a number");
        if fields[i_split] == "train" {
            train.push((speed, litres));
        } else {
            test.push((speed, litres));
        }
    }
    (train, test)
}

/// Solve a x = b by Gaussian elimination with partial pivoting.
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> {
    let n = b.len();
    // The augmented matrix, a fresh copy so a and b are untouched.
    let mut m: Vec<Vec<f64>> = a
        .iter()
        .zip(b)
        .map(|(row, &bi)| row.iter().copied().chain([bi]).collect())
        .collect();
    for col in 0..n {
        // Swap up the row with the largest entry in this column, which keeps
        // the rounding error small. f64 isn't Ord, so compare with total_cmp.
        let pivot = (col..n)
            .max_by(|&r, &s| m[r][col].abs().total_cmp(&m[s][col].abs()))
            .unwrap();
        m.swap(col, pivot);
        for r in col + 1..n {
            let factor = m[r][col] / m[col][col];
            for c in col..=n {
                m[r][c] -= factor * m[col][c];
            }
        }
    }
    // Back substitution, from the last unknown up.
    let mut x = vec![0.0; n];
    for r in (0..n).rev() {
        let rest: f64 = (r + 1..n).map(|c| m[r][c] * x[c]).sum();
        x[r] = (m[r][n] - rest) / m[r][r];
    }
    x
}

/// Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i
/// of Z is 1, z_i, z_i^2, ..., z_i^degree.
fn fit(points: &[(f64, f64)], degree: usize, scale: impl Fn(f64) -> f64) -> Vec<f64> {
    let size = degree + 1;
    let mut a = vec![vec![0.0; size]; size];
    let mut b = vec![0.0; size];
    for &(x, y) in points {
        let z = scale(x);
        for i in 0..size {
            b[i] += y * z.powi(i as i32);
            for j in 0..size {
                a[i][j] += z.powi((i + j) as i32);
            }
        }
    }
    solve(&a, &b)
}

fn rmse(coefs: &[f64], points: &[(f64, f64)], scale: impl Fn(f64) -> f64) -> f64 {
    let total: f64 = points
        .iter()
        .map(|&(x, y)| {
            let z = scale(x);
            let predicted: f64 = coefs.iter().enumerate().map(|(i, c)| c * z.powi(i as i32)).sum();
            (predicted - y).powi(2)
        })
        .sum();
    (total / points.len() as f64).sqrt()
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let (train, test) = read(&path);

    // Map the training speeds onto -1 to 1. Raw speeds to the 16th power
    // (the largest entry at degree 8) would swamp the small ones and make
    // the equations hard to solve accurately.
    let low = train.iter().map(|p| p.0).fold(f64::INFINITY, f64::min);
    let high = train.iter().map(|p| p.0).fold(f64::NEG_INFINITY, f64::max);
    let (mid, half) = ((low + high) / 2.0, (high - low) / 2.0);
    let scale = |x: f64| (x - mid) / half;

    println!("train_count {}", train.len());
    println!("test_count {}", test.len());
    let errors: Vec<(f64, f64)> = (1..=MAX_DEGREE)
        .map(|degree| {
            let coefs = fit(&train, degree, scale);
            (rmse(&coefs, &train, scale), rmse(&coefs, &test, scale))
        })
        .collect();
    for (degree, (train_error, _)) in (1..).zip(&errors) {
        println!("train_rmse_d{degree} {train_error:.6}");
    }
    for (degree, (_, test_error)) in (1..).zip(&errors) {
        println!("test_rmse_d{degree} {test_error:.6}");
    }
}
