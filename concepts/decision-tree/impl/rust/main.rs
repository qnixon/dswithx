//! A decision tree classifier (CART with Gini impurity), using only the
//! standard library.
//!
//! Grows a tree on the training days by always making the split that leaves
//! the two sides purest, then predicts rain for the test days. Prints the tree
//! in preorder: each node is either a split (feature and threshold) or a leaf
//! (its prediction).

use std::env;
use std::fs;

const FEATURES: [&str; 3] = ["humidity", "pressure", "wind"];
const MAX_DEPTH: usize = 3;
const MIN_SIZE: usize = 5;

struct Day {
    x: [f64; 3],
    rain: bool,
}

/// A node is exactly one of two things, and the enum says so. A tree is
/// recursive, so the children sit behind a Box (a pointer to the heap);
/// otherwise a Node would have to contain itself and have no fixed size.
enum Node {
    Leaf(bool),
    Split {
        feature: usize,
        threshold: f64,
        left: Box<Node>,
        right: Box<Node>,
    },
}

/// Splits the file into training and test days. There is no CSV parser in
/// the standard library; the file has no quoted fields, so commas suffice.
fn read(path: &str) -> (Vec<Day>, Vec<Day>) {
    let text = fs::read_to_string(path).expect("cannot read data file");
    let mut lines = text.lines();
    let header: Vec<&str> = lines.next().expect("empty file").split(',').collect();
    let column = |name| {
        header
            .iter()
            .position(|&h| h == name)
            .expect("column not found")
    };
    let (feature_ix, rain_ix, split_ix) = (FEATURES.map(column), column("rain"), column("split"));

    let (mut train, mut test) = (Vec::new(), Vec::new());
    for line in lines {
        let fields: Vec<&str> = line.split(',').collect();
        let day = Day {
            x: feature_ix.map(|i| fields[i].parse().unwrap()),
            rain: fields[rain_ix] == "yes",
        };
        if fields[split_ix] == "train" {
            train.push(day);
        } else {
            test.push(day);
        }
    }
    (train, test)
}

fn count_yes(days: &[&Day]) -> usize {
    days.iter().filter(|d| d.rain).count()
}

/// Chance that two days drawn at random (with replacement) disagree.
fn gini(days: &[&Day]) -> f64 {
    let p = count_yes(days) as f64 / days.len() as f64;
    1.0 - p * p - (1.0 - p) * (1.0 - p)
}

/// Rain only on a strict majority; an even split predicts no rain.
fn majority(days: &[&Day]) -> bool {
    2 * count_yes(days) > days.len()
}

/// The (score, feature, threshold) with the lowest weighted Gini impurity.
/// Features are tried in column order and thresholds from smallest to largest;
/// only a strictly lower score replaces the best so far.
fn best_split(days: &[&Day]) -> Option<(f64, usize, f64)> {
    let mut best: Option<(f64, usize, f64)> = None;
    for f in 0..FEATURES.len() {
        let mut values: Vec<f64> = days.iter().map(|d| d.x[f]).collect();
        values.sort_by(f64::total_cmp); // f64 isn't Ord, so sort() won't compile
        values.dedup(); // drop repeats, leaving the distinct values
        for pair in values.windows(2) {
            let threshold = (pair[0] + pair[1]) / 2.0;
            let (left, right): (Vec<&Day>, Vec<&Day>) =
                days.iter().partition(|d| d.x[f] <= threshold);
            let score = (left.len() as f64 * gini(&left) + right.len() as f64 * gini(&right))
                / days.len() as f64;
            if best.is_none_or(|(s, _, _)| score < s) {
                best = Some((score, f, threshold));
            }
        }
    }
    best
}

/// Days are passed as references, so growing the tree never copies them.
fn grow(days: &[&Day], depth: usize) -> Node {
    let impurity = gini(days);
    if impurity == 0.0 || days.len() < MIN_SIZE || depth == MAX_DEPTH {
        return Node::Leaf(majority(days));
    }
    match best_split(days) {
        Some((score, feature, threshold)) if score < impurity => {
            let (left, right): (Vec<&Day>, Vec<&Day>) =
                days.iter().partition(|d| d.x[feature] <= threshold);
            Node::Split {
                feature,
                threshold,
                left: Box::new(grow(&left, depth + 1)),
                right: Box::new(grow(&right, depth + 1)),
            }
        }
        _ => Node::Leaf(majority(days)), // no split makes the sides purer
    }
}

fn predict(node: &Node, x: &[f64; 3]) -> bool {
    match node {
        Node::Leaf(rain) => *rain,
        Node::Split { feature, threshold, left, right } => {
            predict(if x[*feature] <= *threshold { left } else { right }, x)
        }
    }
}

/// Every node, parents before children, left subtree before right.
fn preorder<'a>(node: &'a Node, out: &mut Vec<&'a Node>) {
    out.push(node);
    if let Node::Split { left, right, .. } = node {
        preorder(left, out);
        preorder(right, out);
    }
}

fn yes_no(rain: bool) -> &'static str {
    if rain { "yes" } else { "no" }
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let (train, test) = read(&path);
    let tree = grow(&train.iter().collect::<Vec<&Day>>(), 0);

    println!("train_count {}", train.len());
    println!("test_count {}", test.len());
    let mut nodes = Vec::new();
    preorder(&tree, &mut nodes);
    let mut leaves = 0;
    for (i, node) in nodes.iter().enumerate() {
        let k = i + 1;
        match node {
            Node::Leaf(rain) => {
                println!("node_{k}_predict {}", yes_no(*rain));
                leaves += 1;
            }
            Node::Split { feature, threshold, .. } => {
                println!("node_{k}_feature {}", FEATURES[*feature]);
                println!("node_{k}_threshold {threshold:.6}");
            }
        }
    }
    println!("leaves {leaves}");

    let correct = |days: &[Day]| days.iter().filter(|d| predict(&tree, &d.x) == d.rain).count();
    println!("train_accuracy {:.6}", correct(&train) as f64 / train.len() as f64);
    println!("correct {}", correct(&test));
    println!("accuracy {:.6}", correct(&test) as f64 / test.len() as f64);
}
