//! Categorical naive Bayes with add-one (Laplace) smoothing, standard library only.
//!
//! Learns P(label) and P(feature value | label) by counting training rows, then
//! labels each test row with the label that has the highest log-probability.

use std::collections::{BTreeMap, HashMap, HashSet};
use std::env;
use std::fs;

const FEATURES: [&str; 3] = ["has_link", "mentions_money", "known_sender"];
const LABEL: &str = "label";

/// Each row as a map from column name to value. There is no CSV parser in the
/// standard library; the file has no quoted fields, so commas suffice.
fn read_rows(text: &str) -> Vec<HashMap<&str, &str>> {
    let mut lines = text.lines();
    let header: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    lines
        .map(|line| header.iter().copied().zip(line.split(',')).collect())
        .collect()
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let text = fs::read_to_string(path).expect("cannot read data file");
    let rows = read_rows(&text);
    let (train, test): (Vec<_>, Vec<_>) = rows.iter().partition(|row| row["split"] == "train");

    // A BTreeMap keeps its keys sorted, so the labels come out alphabetically.
    let mut label_counts: BTreeMap<&str, usize> = BTreeMap::new();
    // value_counts[(feature, value, label)] = number of training rows
    let mut value_counts: HashMap<(&str, &str, &str), usize> = HashMap::new();
    for row in &train {
        *label_counts.entry(row[LABEL]).or_default() += 1;
        for f in FEATURES {
            *value_counts.entry((f, row[f], row[LABEL])).or_default() += 1;
        }
    }
    let distinct_values: HashMap<&str, usize> = FEATURES
        .iter()
        .map(|&f| {
            (
                f,
                train.iter().map(|row| row[f]).collect::<HashSet<_>>().len(),
            )
        })
        .collect();

    let log_score = |row: &HashMap<&str, &str>, label: &str| {
        // Logs turn the product of probabilities into a sum, avoiding underflow.
        let n_label = label_counts[label] as f64;
        let mut score = (n_label / train.len() as f64).ln();
        for f in FEATURES {
            // Add-one smoothing: an unseen value never gets probability zero.
            let count = value_counts.get(&(f, row[f], label)).copied().unwrap_or(0) + 1;
            score += (count as f64 / (n_label + distinct_values[f] as f64)).ln();
        }
        score
    };

    let classify = |row: &HashMap<&str, &str>| {
        // Labels are tried in alphabetical order, and only a strictly higher
        // score replaces the best, so an exact tie goes to the first.
        let mut best: Option<(&str, f64)> = None;
        for &label in label_counts.keys() {
            let score = log_score(row, label);
            if best.is_none_or(|(_, best_score)| score > best_score) {
                best = Some((label, score));
            }
        }
        best.expect("no labels").0
    };

    let correct = test
        .iter()
        .filter(|row| classify(row) == row[LABEL])
        .count();

    println!("train_count {}", train.len());
    println!("test_count {}", test.len());
    println!("correct {correct}");
    println!("accuracy {:.6}", correct as f64 / test.len() as f64);
}
