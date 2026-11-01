//! Principal component analysis by power iteration, using only the standard
//! library.
//!
//! Standardizes the four scores, builds their correlation matrix, and finds
//! the top two eigenvectors (the principal components): power iteration finds
//! the first, then deflation removes it from the matrix so the same steps find
//! the second.

use std::env;
use std::fs;

const SUBJECTS: [&str; K] = ["math", "physics", "reading", "writing"];
const K: usize = 4;
const STEPS: usize = 1000;

/// Fixed-size arrays: the length is part of the type, and they are `Copy`,
/// so passing one to a function hands over a copy.
type Vector = [f64; K];
type Matrix = [Vector; K];

/// There is no CSV parser in the standard library; the file has no quoted
/// fields, so commas suffice.
fn read(path: &str) -> Vec<Vector> {
    let text = fs::read_to_string(path).expect("cannot read data file");
    let mut lines = text.lines();
    let header: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    let index = SUBJECTS.map(|name| {
        header
            .iter()
            .position(|&h| h == name)
            .expect("column not found")
    });
    lines
        .map(|line| {
            let fields: Vec<&str> = line.split(',').collect();
            index.map(|i| fields[i].parse().unwrap())
        })
        .collect()
}

fn dot(u: &Vector, v: &Vector) -> f64 {
    u.iter().zip(v).map(|(a, b)| a * b).sum()
}

fn mat_vec(m: &Matrix, v: &Vector) -> Vector {
    m.map(|row| dot(&row, v))
}

fn normalize(v: Vector) -> Vector {
    let length = dot(&v, &v).sqrt();
    v.map(|x| x / length)
}

/// Power iteration: multiply by the matrix and rescale, STEPS times.
/// Returns the eigenvalue and the eigenvector.
fn top_eigenvector(m: &Matrix) -> (f64, Vector) {
    let mut v = [0.0; K];
    v[0] = 1.0;
    for _ in 0..STEPS {
        v = normalize(mat_vec(m, &v));
    }
    // An eigenvector can point either way; make its first entry positive.
    if v[0] < 0.0 {
        v = v.map(|x| -x);
    }
    (dot(&v, &mat_vec(m, &v)), v)
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let rows = read(&path);
    let n = rows.len() as f64;

    // Standardize each column to mean 0 and (sample) standard deviation 1.
    // `columns` is [0, 1, 2, 3]; mapping over it builds a new fixed-size array.
    let columns: [usize; K] = std::array::from_fn(|j| j);
    let means = columns.map(|j| rows.iter().map(|r| r[j]).sum::<f64>() / n);
    let sds = columns.map(|j| {
        let squares: f64 = rows.iter().map(|r| (r[j] - means[j]).powi(2)).sum();
        (squares / (n - 1.0)).sqrt()
    });
    let z: Vec<Vector> = rows
        .iter()
        .map(|r| columns.map(|j| (r[j] - means[j]) / sds[j]))
        .collect();

    // The correlation matrix: the covariance of the standardized columns.
    let corr: Matrix =
        columns.map(|i| columns.map(|j| z.iter().map(|r| r[i] * r[j]).sum::<f64>() / (n - 1.0)));

    let (value_1, pc_1) = top_eigenvector(&corr);
    // Deflation: subtract the first component's share, leaving the rest.
    let deflated = columns.map(|i| columns.map(|j| corr[i][j] - value_1 * pc_1[i] * pc_1[j]));
    let (value_2, pc_2) = top_eigenvector(&deflated);

    println!("count {}", rows.len());
    for (c, (value, pc)) in [(value_1, pc_1), (value_2, pc_2)].iter().enumerate() {
        let c = c + 1;
        println!("eigenvalue_{c} {value:.6}");
        // Standardized columns each have variance 1, so the total is K.
        println!("explained_{c} {:.6}", value / K as f64);
        for (subject, loading) in SUBJECTS.iter().zip(pc) {
            println!("pc{c}_{subject} {loading:.6}");
        }
    }
    println!("student_1_pc1 {:.6}", dot(&z[0], &pc_1));
    println!("student_1_pc2 {:.6}", dot(&z[0], &pc_2));
}
