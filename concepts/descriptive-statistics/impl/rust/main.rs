//! Descriptive statistics on one CSV column, using only the standard library.
//!
//! Rust's standard library has no statistics functions at all, so every
//! formula is written out. There is no CSV parser either; the file has no
//! quoted fields, so splitting each line on commas is enough.

use std::env;
use std::fs;

const COLUMN: &str = "minutes";

/// Reads one column, found by its header name, as floating-point numbers.
fn read_column(path: &str, column: &str) -> Vec<f64> {
    let text = fs::read_to_string(path).expect("cannot read data file");
    let mut lines = text.lines();
    let header: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    let index = header
        .iter()
        .position(|&name| name == column)
        .expect("column not found");
    lines
        .map(|line| line.split(',').nth(index).unwrap().parse().unwrap())
        .collect()
}

fn median(sorted: &[f64]) -> f64 {
    let n = sorted.len();
    let middle = n / 2;
    if n % 2 == 1 {
        sorted[middle]
    } else {
        (sorted[middle - 1] + sorted[middle]) / 2.0
    }
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let mut values = read_column(&path, COLUMN);
    // f64 has no total order (NaN), so plain sort() won't compile;
    // total_cmp supplies one.
    values.sort_by(f64::total_cmp);

    let n = values.len();
    let total: f64 = values.iter().sum();
    let mean = total / n as f64;
    // Sample variance divides by n - 1, not n (Bessel's correction).
    let variance = values.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / (n - 1) as f64;
    let (min, max) = (values[0], values[n - 1]);

    let results = [
        ("sum", total),
        ("mean", mean),
        ("median", median(&values)),
        ("min", min),
        ("max", max),
        ("range", max - min),
        ("variance", variance),
        ("std_dev", variance.sqrt()),
    ];

    println!("count {n}");
    for (name, value) in results {
        println!("{name} {value:.6}");
    }
}
