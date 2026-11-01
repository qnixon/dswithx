//! k-nearest neighbors classification, using only the standard library.
//!
//! Each test seed is labelled with the majority variety among its K nearest
//! training seeds, by Euclidean distance.

use std::env;
use std::fs;

const K: usize = 5;
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

fn classify(point: &[f64; 2], train: &[Seed]) -> String {
    // Sort references to the training seeds by distance. sort_by is stable,
    // so equal distances keep file order. f64 isn't Ord, hence total_cmp.
    let mut nearest: Vec<&Seed> = train.iter().collect();
    nearest.sort_by(|a, b| distance(point, &a.features).total_cmp(&distance(point, &b.features)));

    // Count the votes in first-seen order, so a tied vote would go to the
    // label met first among the nearest.
    let mut votes: Vec<(&str, usize)> = Vec::new();
    for seed in &nearest[..K] {
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

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let (train, test) = read(&path);
    let correct = test
        .iter()
        .filter(|seed| classify(&seed.features, &train) == seed.label)
        .count();

    println!("train_count {}", train.len());
    println!("test_count {}", test.len());
    println!("correct {correct}");
    println!("accuracy {:.6}", correct as f64 / test.len() as f64);
}
