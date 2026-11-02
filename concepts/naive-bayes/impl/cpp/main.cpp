// Categorical naive Bayes with add-one (Laplace) smoothing, using only the C++
// standard library.
//
// Learns P(label) and P(feature value | label) by counting training rows, then
// labels each test row with the label that has the highest log-probability.

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <fstream>
#include <map>
#include <print>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <tuple>
#include <vector>

const std::vector<std::string> FEATURES = {"has_link", "mentions_money", "known_sender"};

// One email: its feature values in FEATURES order, its label, and its split.
struct Row {
    std::vector<std::string> values;
    std::string label;
    std::string split;
};

// Split one line at every comma.
std::vector<std::string> split(const std::string& line) {
    std::vector<std::string> fields;
    std::stringstream stream(line);
    std::string field;
    while (std::getline(stream, field, ',')) {
        fields.push_back(field);
    }
    return fields;
}

// Every row of the CSV file, with columns found by name and kept as text.
std::vector<Row> read_rows(const std::string& path) {
    std::ifstream file(path);
    std::string line;
    std::getline(file, line);
    std::vector<std::string> header = split(line);
    auto column = [&header](const std::string& name) {
        auto found = std::find(header.begin(), header.end(), name);
        if (found == header.end()) {
            throw std::runtime_error("no column " + name);
        }
        return static_cast<std::size_t>(found - header.begin());
    };
    std::vector<std::size_t> feature_cols;
    for (const std::string& feature : FEATURES) {
        feature_cols.push_back(column(feature));
    }
    std::size_t label_col = column("label");
    std::size_t split_col = column("split");

    std::vector<Row> rows;
    while (std::getline(file, line)) {
        if (line.empty()) {
            continue;
        }
        std::vector<std::string> fields = split(line);
        Row row;
        for (std::size_t col : feature_cols) {
            row.values.push_back(fields.at(col));
        }
        row.label = fields.at(label_col);
        row.split = fields.at(split_col);
        rows.push_back(row);
    }
    return rows;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    std::vector<Row> rows = read_rows(argv[1]);
    std::vector<Row> train;
    std::vector<Row> test;
    for (const Row& row : rows) {
        if (row.split == "train") train.push_back(row);
        if (row.split == "test") test.push_back(row);
    }
    if (train.empty() || test.empty()) {
        std::println(stderr, "need training and test rows");
        return 1;
    }

    // A std::map keeps its keys sorted, and a std::tuple compares field by
    // field, so a (feature, value, label) tuple works as a key.
    using Key = std::tuple<std::string, std::string, std::string>;
    std::map<std::string, int> label_counts;
    std::map<Key, int> value_counts;
    std::vector<std::set<std::string>> distinct_values(FEATURES.size());
    for (const Row& row : train) {
        // operator[] inserts a zero for a missing key, so ++ starts counting at 1.
        label_counts[row.label]++;
        for (std::size_t f = 0; f < FEATURES.size(); f++) {
            value_counts[{FEATURES[f], row.values[f], row.label}]++;
            distinct_values[f].insert(row.values[f]);
        }
    }

    auto log_score = [&](const Row& row, const std::string& label) {
        int label_count = label_counts.at(label);
        // Logs turn the product of probabilities into a sum, avoiding underflow.
        double score = std::log(static_cast<double>(label_count) / train.size());
        for (std::size_t f = 0; f < FEATURES.size(); f++) {
            // find, unlike operator[], leaves the map alone when the key is missing.
            auto found = value_counts.find({FEATURES[f], row.values[f], label});
            int seen = found == value_counts.end() ? 0 : found->second;
            // Add-one smoothing: an unseen value never gets probability zero.
            score += std::log(static_cast<double>(seen + 1) /
                              (label_count + static_cast<int>(distinct_values[f].size())));
        }
        return score;
    };

    // A std::map visits its keys in sorted order, and only a strictly higher
    // score replaces the best, so an exact tie goes to the first label.
    auto classify = [&](const Row& row) {
        std::string best;
        double best_score = 0.0;
        for (const auto& [label, count] : label_counts) {
            double score = log_score(row, label);
            if (best.empty() || score > best_score) {
                best = label;
                best_score = score;
            }
        }
        return best;
    };

    int correct = 0;
    for (const Row& row : test) {
        if (classify(row) == row.label) correct++;
    }

    std::println("train_count {}", train.size());
    std::println("test_count {}", test.size());
    std::println("correct {}", correct);
    std::println("accuracy {:.6f}", static_cast<double>(correct) / test.size());
}
