// k-nearest neighbors classification, using only the C++ standard library.
//
// Each test seed is labelled with the majority variety among its K nearest
// training seeds, by Euclidean distance.

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <fstream>
#include <map>
#include <print>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

constexpr std::size_t K = 5;

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

std::string classify(const Seed& point, const std::vector<Seed>& train) {
    // Pointers to the training seeds, so sorting doesn't copy the labels.
    std::vector<const Seed*> nearest;
    for (const Seed& seed : train) {
        nearest.push_back(&seed);
    }
    auto distance = [&point](const Seed* seed) {
        return std::hypot(point.length - seed->length, point.width - seed->width);
    };
    // std::sort isn't stable; stable_sort keeps equal distances in file order.
    std::ranges::stable_sort(nearest, [&](const Seed* a, const Seed* b) {
        return distance(a) < distance(b);
    });

    // Count the K nearest labels' votes. A std::map starts each new key at 0.
    std::map<std::string, int> votes;
    for (std::size_t i = 0; i < K; i++) {
        votes[nearest[i]->variety]++;
    }
    // The map keeps its keys in alphabetical order, so walk the nearest
    // seeds instead: the first label to reach the highest count wins.
    std::string best;
    int best_votes = 0;
    for (std::size_t i = 0; i < K; i++) {
        const std::string& label = nearest[i]->variety;
        if (votes[label] > best_votes) {
            best = label;
            best_votes = votes[label];
        }
    }
    return best;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    std::vector<Seed> train, test;
    read_seeds(argv[1], train, test);
    if (train.size() < K || test.empty()) {
        throw std::runtime_error("too few seeds");
    }

    // count_if counts the test seeds whose predicted variety is right.
    auto correct = std::ranges::count_if(test, [&train](const Seed& seed) {
        return classify(seed, train) == seed.variety;
    });

    std::println("train_count {}", train.size());
    std::println("test_count {}", test.size());
    std::println("correct {}", correct);
    std::println("accuracy {:.6f}", static_cast<double>(correct) / test.size());
}
