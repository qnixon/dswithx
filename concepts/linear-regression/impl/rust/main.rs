//! Simple linear regression by least squares, using only the standard library.
//!
//! Fits score = intercept + slope * hours. Rust's standard library has no
//! statistics or CSV support, so the sums and the line splitting are written
//! out; the file has no quoted fields.

use std::env;
use std::fs;

const X: &str = "hours";
const Y: &str = "score";

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let text = fs::read_to_string(path).expect("cannot read data file");
    let mut lines = text.lines();
    let header: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    let column = |name| {
        header
            .iter()
            .position(|&h| h == name)
            .expect("column not found")
    };
    let (ix, iy) = (column(X), column(Y));

    let mut xs = Vec::new();
    let mut ys = Vec::new();
    for line in lines {
        let fields: Vec<&str> = line.split(',').collect();
        xs.push(fields[ix].parse::<f64>().unwrap());
        ys.push(fields[iy].parse::<f64>().unwrap());
    }

    let n = xs.len() as f64;
    let mean_x = xs.iter().sum::<f64>() / n;
    let mean_y = ys.iter().sum::<f64>() / n;

    // Sums of squared deviations and of cross-products.
    let sxx: f64 = xs.iter().map(|x| (x - mean_x).powi(2)).sum();
    let syy: f64 = ys.iter().map(|y| (y - mean_y).powi(2)).sum();
    let sxy: f64 = xs
        .iter()
        .zip(&ys)
        .map(|(x, y)| (x - mean_x) * (y - mean_y))
        .sum();

    let slope = sxy / sxx;
    let intercept = mean_y - slope * mean_x;
    let r = sxy / (sxx * syy).sqrt();

    println!("count {}", xs.len());
    println!("slope {slope:.6}");
    println!("intercept {intercept:.6}");
    println!("r {r:.6}");
    println!("r_squared {:.6}", r * r);
}
