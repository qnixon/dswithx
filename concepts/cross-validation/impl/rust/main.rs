//! 5-fold cross-validation for k-nearest neighbors, using only the standard
//! library.
//!
//! Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
//! holding out one fold at a time, picks the k with the best average accuracy,
//! and then scores that k once on the untouched test seeds.

use std::env;
use std::fs;

const FOLDS: usize = 5;
const FEATURES: [&str; 2] = ["length_mm", "width_mm"];
const LABEL: &str = "variety";

struct Seed {
    features: [f64; 2],
    label: String,
}

/// Splits the file into training and test seeds. There is no CSV parser in
/// the standard library; the file has no quoted fields, so commas suffice.
fn read(path: &str) -> (Vec<Seed>, Vec<Seed>) {
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
        let seed = Seed {
            features: feature_ix.map(|i| fields[i].parse().unwrap()),
            label: fields[label_ix].to_string(),
        };
        if fields[split_ix] == "train" {
            train.push(seed);
        } else {
            test.push(seed);
        }
    }
    (train, test)
}

fn distance(a: &[f64; 2], b: &[f64; 2]) -> f64 {
    a.iter()
        .zip(b)
        .map(|(p, q)| (p - q).powi(2))
        .sum::<f64>()
        .sqrt()
}

/// `train` holds references to the training seeds, so a fold's split copies
/// no seeds.
fn classify(point: &[f64; 2], train: &[&Seed], k: usize) -> String {
    // Sort the references by distance. sort_by is stable, so equal distances
    // keep file order. f64 isn't Ord, hence total_cmp.
    let mut nearest = train.to_vec();
    nearest.sort_by(|a, b| distance(point, &a.features).total_cmp(&distance(point, &b.features)));

    // Count the votes in first-seen order, so a tied vote would go to the
    // label met first among the nearest.
    let mut votes: Vec<(&str, usize)> = Vec::new();
    for seed in &nearest[..k] {
        match votes.iter_mut().find(|(label, _)| *label == seed.label) {
            Some((_, count)) => *count += 1,
            None => votes.push((&seed.label, 1)),
        }
    }
    // max_by_key returns the *last* maximum, so scan for the first by hand.
    let mut winner = votes[0];
    for &vote in &votes[1..] {
        if vote.1 > winner.1 {
            winner = vote;
        }
    }
    winner.0.to_string()
}

fn count_correct(points: &[Seed], train: &[&Seed], k: usize) -> usize {
    points
        .iter()
        .filter(|seed| classify(&seed.features, train, k) == seed.label)
        .count()
}

/// Fold f is rows f*size up to (f+1)*size. The rows are already shuffled, so
/// consecutive blocks make fair folds.
fn cv_accuracy(train: &[Seed], k: usize) -> f64 {
    let size = train.len() / FOLDS;
    let mut correct = 0;
    for f in 0..FOLDS {
        let (start, end) = (f * size, (f + 1) * size);
        let held_out = &train[start..end];
        // chain joins the rows before and after the fold, in file order.
        let rest: Vec<&Seed> = train[..start].iter().chain(&train[end..]).collect();
        correct += count_correct(held_out, &rest, k);
    }
    correct as f64 / train.len() as f64
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let (train, test) = read(&path);

    println!("train_count {}", train.len());
    println!("test_count {}", test.len());
    let (mut best_k, mut best_accuracy) = (0, -1.0);
    // Odd k only. A strict > means a tie keeps the smaller k.
    for k in (1..=15).step_by(2) {
        let accuracy = cv_accuracy(&train, k);
        println!("cv_accuracy_k{k} {accuracy:.6}");
        if accuracy > best_accuracy {
            (best_k, best_accuracy) = (k, accuracy);
        }
    }

    // Only now touch the test seeds, once, with the chosen k and all of train.
    let all: Vec<&Seed> = train.iter().collect();
    let correct = count_correct(&test, &all, best_k);
    println!("best_k {best_k}");
    println!("test_correct {correct}");
    println!("test_accuracy {:.6}", correct as f64 / test.len() as f64);
}
