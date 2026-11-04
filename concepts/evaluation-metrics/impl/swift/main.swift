// Evaluation metrics for a binary classifier, using only Swift's standard
// library and Foundation, which ships with it.
//
// Reads each part's true label and the model's score, then reports the
// confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
// the accuracy of never flagging anything, and the area under the ROC curve.

import Foundation

func six(_ x: Double) -> String { String(format: "%.6f", x) }

// Read defective,score lines into tuples. split skips empty pieces, so a
// blank last line doesn't become a row. Double(_:) gives an optional, which
// ! unwraps.
let text = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
var parts: [(defective: Bool, score: Double)] = []
for line in text.split(separator: "\n").dropFirst() {  // dropFirst skips the header
    let fields = line.split(separator: ",")
    parts.append((defective: fields[0] == "1", score: Double(fields[1])!))
}
let n = Double(parts.count)
let defectiveCount = parts.filter { $0.defective }.count

// Sort every part into one of four counts at this threshold, then print the
// counts and the ratios built from them.
func report(_ suffix: String, _ threshold: Double) {
    var tp = 0, fp = 0, fn = 0, tn = 0
    for part in parts {
        let flagged = part.score >= threshold  // flagged when the score reaches it
        switch (flagged, part.defective) {
        case (true, true): tp += 1
        case (true, false): fp += 1
        case (false, true): fn += 1
        case (false, false): tn += 1
        }
    }
    // Swift never mixes Int and Double silently, so each count is converted.
    let accuracy = Double(tp + tn) / n
    let precision = Double(tp) / Double(tp + fp)  // of the flagged, how many defective
    let recall = Double(tp) / Double(tp + fn)     // of the defective, how many flagged
    let f1 = 2 * precision * recall / (precision + recall)

    print("tp_at_\(suffix)", tp)
    print("fp_at_\(suffix)", fp)
    print("fn_at_\(suffix)", fn)
    print("tn_at_\(suffix)", tn)
    print("accuracy_at_\(suffix)", six(accuracy))
    print("precision_at_\(suffix)", six(precision))
    print("recall_at_\(suffix)", six(recall))
    print("f1_at_\(suffix)", six(f1))
}

// The chance that a random defective part outscores a random good one.
// Compare every pair, scoring 2 for a win and 1 for a tie, so the count stays
// a whole number until the final division.
func auc() -> Double {
    let defective = parts.filter { $0.defective }.map { $0.score }
    let good = parts.filter { !$0.defective }.map { $0.score }
    var points = 0
    for d in defective {
        for g in good {
            if d > g {
                points += 2
            } else if d == g {  // equal text in the file parses to equal doubles
                points += 1
            }
        }
    }
    return Double(points) / Double(2 * defective.count * good.count)
}

print("parts", parts.count)
print("defective", defectiveCount)
// Never flagging anything is right about every good part.
print("baseline_accuracy", six(Double(parts.count - defectiveCount) / n))
report("50", 0.5)
report("30", 0.3)
print("auc", six(auc()))
