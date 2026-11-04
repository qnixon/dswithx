// Evaluation metrics for a binary classifier, using only the C++ standard
// library.
//
// Reads each part's true label and the model's score, then reports the
// confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
// the accuracy of never flagging anything, and the area under the ROC curve.

#include <algorithm>
#include <fstream>
#include <print>
#include <string>
#include <string_view>
#include <vector>

struct Part {
    bool defective;
    double score;
};

// Sort every part into one of four counts at this threshold, then print the
// counts and the ratios built from them.
void report(const std::vector<Part>& parts, std::string_view suffix, double threshold) {
    int tp = 0, fp = 0, fn = 0, tn = 0;
    for (const auto& [defective, score] : parts) {  // structured binding unpacks a Part
        bool flagged = score >= threshold;  // flagged when the score reaches it
        if (flagged && defective) {
            tp++;
        } else if (flagged) {
            fp++;
        } else if (defective) {
            fn++;
        } else {
            tn++;
        }
    }
    double accuracy = static_cast<double>(tp + tn) / parts.size();
    double precision = static_cast<double>(tp) / (tp + fp);  // of the flagged, how many defective
    double recall = static_cast<double>(tp) / (tp + fn);     // of the defective, how many flagged
    double f1 = 2 * precision * recall / (precision + recall);

    std::println("tp_at_{} {}", suffix, tp);
    std::println("fp_at_{} {}", suffix, fp);
    std::println("fn_at_{} {}", suffix, fn);
    std::println("tn_at_{} {}", suffix, tn);
    std::println("accuracy_at_{} {:.6f}", suffix, accuracy);
    std::println("precision_at_{} {:.6f}", suffix, precision);
    std::println("recall_at_{} {:.6f}", suffix, recall);
    std::println("f1_at_{} {:.6f}", suffix, f1);
}

// The chance that a random defective part outscores a random good one.
// Compare every pair, scoring 2 for a win and 1 for a tie, so the count
// stays a whole number until the final division.
double auc(const std::vector<Part>& parts) {
    std::vector<double> defective, good;
    for (const auto& part : parts) {
        (part.defective ? defective : good).push_back(part.score);
    }
    long points = 0;
    for (double d : defective) {
        for (double g : good) {
            if (d > g) {
                points += 2;
            } else if (d == g) {  // equal text in the file parses to equal doubles
                points += 1;
            }
        }
    }
    return static_cast<double>(points) / (2.0 * defective.size() * good.size());
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }

    // Read defective,score lines.
    std::ifstream file(argv[1]);
    std::string line;
    std::getline(file, line);  // skip the header
    std::vector<Part> parts;
    while (std::getline(file, line)) {
        auto comma = line.find(',');
        if (comma == std::string::npos) {
            continue;
        }
        parts.push_back({line.substr(0, comma) == "1", std::stod(line.substr(comma + 1))});
    }

    // count_if counts the elements the lambda says yes to.
    auto defective = std::ranges::count_if(parts, [](const Part& p) { return p.defective; });
    std::println("parts {}", parts.size());
    std::println("defective {}", defective);
    // Never flagging anything is right about every good part.
    std::println("baseline_accuracy {:.6f}",
                 static_cast<double>(parts.size() - defective) / parts.size());
    report(parts, "50", 0.5);
    report(parts, "30", 0.3);
    std::println("auc {:.6f}", auc(parts));
}
