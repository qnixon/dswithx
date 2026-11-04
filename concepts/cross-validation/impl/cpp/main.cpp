// 5-fold cross-validation for k-nearest neighbors, using only the C++
// standard library.
//
// Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
// holding out one fold at a time, picks the k with the best average accuracy,
// and then scores that k once on the untouched test seeds.

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <fstream>
#include <map>
#include <print>
#include <span>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

constexpr std::size_t FOLDS = 5;
constexpr std::size_t MAX_K = 15;

// A struct groups one seed's measurements with its variety.
struct Seed {
    double length;
    double width;
    std::string variety;
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

// Read every seed into the training or the test set, by its split column.
void read_seeds(const std::string& path, std::vector<Seed>& train, std::vector<Seed>& test) {
    std::ifstream file(path);
    std::string line;
    std::getline(file, line);
    std::vector<std::string> header = split(line);
    // A lambda that finds a column's position, or throws.
    auto column = [&header](const std::string& name) {
        auto found = std::find(header.begin(), header.end(), name);
        if (found == header.end()) {
            throw std::runtime_error("no column " + name);
        }
        return static_cast<std::size_t>(found - header.begin());
    };
    std::size_t length = column("length_mm"), width = column("width_mm");
    std::size_t variety = column("variety"), which = column("split");

    while (std::getline(file, line)) {
        if (line.empty()) {
            continue;
        }
        std::vector<std::string> fields = split(line);
        Seed seed{std::stod(fields.at(length)), std::stod(fields.at(width)), fields.at(variety)};
        (fields.at(which) == "train" ? train : test).push_back(seed);
    }
}

// The training seeds are passed as pointers, so a fold's split copies no labels.
std::string classify(const Seed& point, std::vector<const Seed*> nearest, std::size_t k) {
    auto distance = [&point](const Seed* seed) {
        return std::hypot(point.length - seed->length, point.width - seed->width);
    };
    // std::sort isn't stable; stable_sort keeps equal distances in file order.
    std::ranges::stable_sort(nearest, [&](const Seed* a, const Seed* b) {
        return distance(a) < distance(b);
    });

    // Count the k nearest labels' votes. A std::map starts each new key at 0.
    std::map<std::string, int> votes;
    for (std::size_t i = 0; i < k; i++) {
        votes[nearest[i]->variety]++;
    }
    // The map keeps its keys in alphabetical order, so walk the nearest
    // seeds instead: the first label to reach the highest count wins.
    std::string best;
    int best_votes = 0;
    for (std::size_t i = 0; i < k; i++) {
        const std::string& label = nearest[i]->variety;
        if (votes[label] > best_votes) {
            best = label;
            best_votes = votes[label];
        }
    }
    return best;
}

// A std::span is a view of part of a vector: a pointer and a length, no copy.
long count_correct(std::span<const Seed> points, const std::vector<const Seed*>& train,
                   std::size_t k) {
    return std::ranges::count_if(points, [&](const Seed& seed) {
        return classify(seed, train, k) == seed.variety;
    });
}

// Fold f is rows f*size up to (f+1)*size. The rows are already shuffled, so
// consecutive blocks make fair folds.
double cv_accuracy(const std::vector<Seed>& train, std::size_t k) {
    std::size_t size = train.size() / FOLDS;
    long correct = 0;
    for (std::size_t f = 0; f < FOLDS; f++) {
        std::size_t start = f * size, end = start + size;
        std::span<const Seed> held_out(train.begin() + start, size);
        // Every other row, in file order, as a pointer.
        std::vector<const Seed*> rest;
        for (std::size_t i = 0; i < train.size(); i++) {
            if (i < start || i >= end) {
                rest.push_back(&train[i]);
            }
        }
        correct += count_correct(held_out, rest, k);
    }
    return static_cast<double>(correct) / train.size();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    std::vector<Seed> train, test;
    read_seeds(argv[1], train, test);
    if (train.size() < FOLDS * MAX_K || test.empty()) {
        throw std::runtime_error("too few seeds");
    }

    std::println("train_count {}", train.size());
    std::println("test_count {}", test.size());
    std::size_t best_k = 0;
    double best_accuracy = -1.0;
    for (std::size_t k = 1; k <= MAX_K; k += 2) {  // odd k only
        double accuracy = cv_accuracy(train, k);
        std::println("cv_accuracy_k{} {:.6f}", k, accuracy);
        if (accuracy > best_accuracy) {  // strictly better, so ties keep the smaller k
            best_k = k;
            best_accuracy = accuracy;
        }
    }

    // Only now touch the test seeds, once, with the chosen k and all of train.
    std::vector<const Seed*> all;
    for (const Seed& seed : train) {
        all.push_back(&seed);
    }
    long correct = count_correct(test, all, best_k);
    std::println("best_k {}", best_k);
    std::println("test_correct {}", correct);
    std::println("test_accuracy {:.6f}", static_cast<double>(correct) / test.size());
}
