//! k-means clustering (Lloyd's algorithm), using only the standard library.
//!
//! Starts from the first K points as centroids, then alternates two steps until
//! no point changes cluster: assign each point to its nearest centroid, and move
//! each centroid to the mean of its points.

use std::env;
use std::fs;

const K: usize = 3;
const MAX_ITERATIONS: usize = 100;

type Point = [f64; 2];

/// Reads the x and y columns by header name. There is no CSV parser in the
/// standard library; the file has no quoted fields, so commas suffice.
fn read_points(path: &str) -> Vec<Point> {
    let text = fs::read_to_string(path).expect("cannot read data file");
    let mut lines = text.lines();
    let header: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    let column = |name| {
        header
            .iter()
            .position(|&h| h == name)
            .expect("column not found")
    };
    let (ix, iy) = (column("x"), column("y"));
    lines
        .map(|line| {
            let fields: Vec<&str> = line.split(',').collect();
            [fields[ix].parse().unwrap(), fields[iy].parse().unwrap()]
        })
        .collect()
}

fn squared_distance(a: &Point, b: &Point) -> f64 {
    (a[0] - b[0]).powi(2) + (a[1] - b[1]).powi(2)
}

fn nearest(point: &Point, centroids: &[Point]) -> usize {
    // A strict < keeps the first of equal distances, so ties go to the lower index.
    let mut best = 0;
    for j in 1..centroids.len() {
        if squared_distance(point, &centroids[j]) < squared_distance(point, &centroids[best]) {
            best = j;
        }
    }
    best
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let points = read_points(&path);

    let mut centroids: Vec<Point> = points[..K].to_vec();
    // Option<Vec> stands for "no assignment yet" before the first pass.
    let mut assignment: Option<Vec<usize>> = None;
    let mut iterations = 0;
    while iterations < MAX_ITERATIONS {
        iterations += 1;
        let new_assignment: Vec<usize> = points.iter().map(|p| nearest(p, &centroids)).collect();
        if assignment.as_ref() == Some(&new_assignment) {
            break; // this unchanged pass still counts
        }
        for (j, centroid) in centroids.iter_mut().enumerate() {
            let members: Vec<&Point> = points
                .iter()
                .zip(&new_assignment)
                .filter(|&(_, &a)| a == j)
                .map(|(p, _)| p)
                .collect();
            if !members.is_empty() {
                // An empty cluster keeps its old centroid.
                let n = members.len() as f64;
                *centroid = [
                    members.iter().map(|p| p[0]).sum::<f64>() / n,
                    members.iter().map(|p| p[1]).sum::<f64>() / n,
                ];
            }
        }
        assignment = Some(new_assignment);
    }

    let assignment = assignment.expect("at least one pass");
    let inertia: f64 = points
        .iter()
        .zip(&assignment)
        .map(|(p, &a)| squared_distance(p, &centroids[a]))
        .sum();

    println!("iterations {iterations}");
    for (j, [x, y]) in centroids.iter().enumerate() {
        println!("centroid_{}_x {x:.6}", j + 1);
        println!("centroid_{}_y {y:.6}", j + 1);
    }
    for j in 0..K {
        let size = assignment.iter().filter(|&&a| a == j).count();
        println!("size_{} {size}", j + 1);
    }
    println!("inertia {inertia:.6}");
}
