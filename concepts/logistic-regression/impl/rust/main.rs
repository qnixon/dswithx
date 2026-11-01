//! Logistic regression by gradient descent, using only the standard library.
//!
//! Predicts whether a student passed from study hours and sleep. Each feature
//! is rescaled with the training rows' mean and standard deviation, then the
//! weights start at zero and take 1000 fixed steps of batch gradient descent
//! on the average log-loss.

use std::env;
use std::fs;

const FEATURES: [&str; 2] = ["hours", "sleep"];
const LABEL: &str = "passed";
const LEARNING_RATE: f64 = 0.5;
const STEPS: usize = 1000;

/// One row: the two features and the 0/1 label.
type Example = ([f64; 2], f64);

/// Splits the file into training and test rows. There is no CSV parser in
/// the standard library; the file has no quoted fields, so commas suffice.
fn read(path: &str) -> (Vec<Example>, Vec<Example>) {
    let text = fs::read_to_string(path).expect("cannot read data file");
    let mut lines = text.lines();
    let header: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    let column = |name| {
        header
            .iter()
            .position(|&h| h == name)
            .expect("column not found")
    };
    let (feature_ix, label_ix, split_ix) = (FEATURES.map(column), column(LABEL), column("split"));

    let (mut train, mut test) = (Vec::new(), Vec::new());
    for line in lines {
        let fields: Vec<&str> = line.split(',').collect();
        let example = (
            feature_ix.map(|i| fields[i].parse().unwrap()),
            fields[label_ix].parse().unwrap(),
        );
        if fields[split_ix] == "train" {
            train.push(example);
        } else {
            test.push(example);
        }
    }
    (train, test)
}

fn sigmoid(z: f64) -> f64 {
    1.0 / (1.0 + (-z).exp())
}

fn dot(w: &[f64; 3], x: &[f64; 3]) -> f64 {
    w.iter().zip(x).map(|(a, b)| a * b).sum()
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let (train, test) = read(&path);
    let n = train.len() as f64;

    // Scale each feature to mean 0 and (sample) standard deviation 1, using
    // the training rows only.
    let means: [f64; 2] = [0, 1].map(|j| train.iter().map(|(x, _)| x[j]).sum::<f64>() / n);
    let sds: [f64; 2] = [0, 1].map(|j| {
        let squares: f64 = train.iter().map(|(x, _)| (x[j] - means[j]).powi(2)).sum();
        (squares / (n - 1.0)).sqrt()
    });
    // The leading 1 multiplies the intercept.
    let scale = |x: &[f64; 2]| -> [f64; 3] {
        [1.0, (x[0] - means[0]) / sds[0], (x[1] - means[1]) / sds[1]]
    };
    let xs: Vec<[f64; 3]> = train.iter().map(|(x, _)| scale(x)).collect();

    let mut weights = [0.0; 3];
    for _ in 0..STEPS {
        // Gradient of the average log-loss: the mean of (p - y) times each
        // input, computed in full before any weight changes.
        let errors: Vec<f64> = xs
            .iter()
            .zip(&train)
            .map(|(x, (_, y))| sigmoid(dot(&weights, x)) - y)
            .collect();
        let gradient: [f64; 3] = [0, 1, 2].map(|j| {
            errors.iter().zip(&xs).map(|(e, x)| e * x[j]).sum::<f64>() / n
        });
        for (w, g) in weights.iter_mut().zip(gradient) {
            *w -= LEARNING_RATE * g;
        }
    }

    let log_loss = -xs
        .iter()
        .zip(&train)
        .map(|(x, (_, y))| {
            let p = sigmoid(dot(&weights, x));
            y * p.ln() + (1.0 - y) * (1.0 - p).ln()
        })
        .sum::<f64>()
        / n;

    let correct = test
        .iter()
        .filter(|(x, y)| {
            let predicted = if sigmoid(dot(&weights, &scale(x))) >= 0.5 { 1.0 } else { 0.0 };
            predicted == *y
        })
        .count();

    println!("train_count {}", train.len());
    println!("test_count {}", test.len());
    println!("intercept {:.6}", weights[0]);
    println!("weight_hours {:.6}", weights[1]);
    println!("weight_sleep {:.6}", weights[2]);
    println!("log_loss {log_loss:.6}");
    println!("correct {correct}");
    println!("accuracy {:.6}", correct as f64 / test.len() as f64);
}
