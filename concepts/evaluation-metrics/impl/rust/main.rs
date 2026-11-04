//! Evaluation metrics for a binary classifier, using only the standard
//! library.
//!
//! Reads each part's true label and the model's score, then reports the
//! confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
//! the accuracy of never flagging anything, and the area under the ROC curve.

use std::env;
use std::fs;

const THRESHOLDS: [(&str, f64); 2] = [("50", 0.5), ("30", 0.3)]; // name suffix, threshold

/// Each part becomes (defective, score). The file has no quoted fields, so
/// commas suffice; columns are found by name in the header.
fn read(path: &str) -> Vec<(bool, f64)> {
    let text = fs::read_to_string(path).expect("cannot read data file");
    let mut lines = text.lines();
    let columns: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    let column = |name| columns.iter().position(|&c| c == name).expect("missing column");
    let (i_label, i_score) = (column("defective"), column("score"));
    lines
        .map(|line| {
            let fields: Vec<&str> = line.split(',').collect();
            let score: f64 = fields[i_score].parse().expect("score must be a number");
            (fields[i_label] == "1", score)
        })
        .collect()
}

fn report(parts: &[(bool, f64)], suffix: &str, threshold: f64) {
    // A part is flagged when its score reaches the threshold.
    let (mut tp, mut fp, mut fn_, mut tn) = (0u32, 0u32, 0u32, 0u32); // `fn` is a keyword
    for &(defective, score) in parts {
        match (score >= threshold, defective) {
            (true, true) => tp += 1,
            (true, false) => fp += 1,
            (false, true) => fn_ += 1,
            (false, false) => tn += 1,
        }
    }

    let ratio = |a: u32, b: u32| a as f64 / b as f64;
    let accuracy = ratio(tp + tn, parts.len() as u32);
    let precision = ratio(tp, tp + fp); // of the flagged parts, how many are defective
    let recall = ratio(tp, tp + fn_); // of the defective parts, how many are flagged
    let f1 = 2.0 * precision * recall / (precision + recall);

    println!("tp_at_{suffix} {tp}");
    println!("fp_at_{suffix} {fp}");
    println!("fn_at_{suffix} {fn_}");
    println!("tn_at_{suffix} {tn}");
    println!("accuracy_at_{suffix} {accuracy:.6}");
    println!("precision_at_{suffix} {precision:.6}");
    println!("recall_at_{suffix} {recall:.6}");
    println!("f1_at_{suffix} {f1:.6}");
}

/// The chance that a random defective part outscores a random good one.
/// Compare every pair, scoring 2 for a win and 1 for a tie, so the count
/// stays a whole number until the final division.
fn auc(parts: &[(bool, f64)]) -> f64 {
    let scores = |want: bool| -> Vec<f64> {
        parts.iter().filter(|p| p.0 == want).map(|p| p.1).collect()
    };
    let (defective, good) = (scores(true), scores(false));
    let mut points = 0u64;
    for &d in &defective {
        for &g in &good {
            if d > g {
                points += 2;
            } else if d == g {
                points += 1;
            }
        }
    }
    points as f64 / (2 * defective.len() * good.len()) as f64
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let parts = read(&path);
    let n = parts.len();
    let defective = parts.iter().filter(|p| p.0).count();

    println!("parts {n}");
    println!("defective {defective}");
    // Never flagging anything is right about every good part.
    println!("baseline_accuracy {:.6}", (n - defective) as f64 / n as f64);
    for (suffix, threshold) in THRESHOLDS {
        report(&parts, suffix, threshold);
    }
    println!("auc {:.6}", auc(&parts));
}
