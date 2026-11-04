//! Exact two-sided permutation test for a difference in means, using only the
//! standard library.
//!
//! If compost made no difference, the "compost" and "control" labels are
//! arbitrary, and any 8 of the 16 plants could have carried the compost label.
//! We try every one of those splits and count how many give a difference at
//! least as large as the one we observed. That fraction is the p-value.

use std::env;
use std::fs;

/// There is no CSV parser in the standard library; the file has no quoted
/// fields, so commas suffice.
fn read(path: &str) -> (Vec<i64>, Vec<i64>) {
    let text = fs::read_to_string(path).expect("cannot read data file");
    let (mut control, mut compost) = (Vec::new(), Vec::new());
    for line in text.lines().skip(1) {
        let (group, grams) = line.split_once(',').expect("expected two fields");
        let grams: i64 = grams.parse().expect("grams must be a whole number");
        match group {
            "control" => control.push(grams),
            "compost" => compost.push(grams),
            other => panic!("unknown group {other}"),
        }
    }
    (control, compost)
}

fn main() {
    let path = env::args().nth(1).expect("usage: main <data.csv>");
    let (control, compost) = read(&path);
    let n = compost.len();
    let plants: Vec<i64> = control.iter().chain(&compost).copied().collect();
    let total: i64 = plants.iter().sum();

    // Both groups have n plants, so comparing totals is the same as comparing
    // means, and totals stay whole numbers: no floating-point near-ties.
    let observed = compost.iter().sum::<i64>() - control.iter().sum::<i64>();

    // Each split is a number whose binary digits mark the chosen plants: bit i
    // set means plant i carries the compost label. Of the 2^16 numbers, the
    // ones with exactly n bits set are the splits.
    let (mut splits, mut as_extreme) = (0u64, 0u64);
    for mask in 0u32..(1 << plants.len()) {
        if mask.count_ones() as usize != n {
            continue;
        }
        let relabeled: i64 = (0..plants.len())
            .filter(|&i| mask >> i & 1 == 1)
            .map(|i| plants[i])
            .sum();
        let difference = relabeled - (total - relabeled);
        splits += 1;
        if difference.abs() >= observed.abs() {
            as_extreme += 1; // two-sided: either direction
        }
    }

    let mean = |xs: &[i64]| xs.iter().sum::<i64>() as f64 / xs.len() as f64;
    println!("control_count {}", control.len());
    println!("compost_count {n}");
    println!("control_mean {:.6}", mean(&control));
    println!("compost_mean {:.6}", mean(&compost));
    println!("observed_difference {:.6}", observed as f64 / n as f64);
    println!("splits {splits}");
    println!("as_extreme {as_extreme}");
    println!("p_value {:.6}", as_extreme as f64 / splits as f64);
}
