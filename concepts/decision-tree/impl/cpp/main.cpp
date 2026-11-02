// A decision tree classifier (CART with Gini impurity), using only the C++
// standard library.
//
// Grows a tree on the training days by always making the split that leaves
// the two sides purest, then predicts rain for the test days. Prints the tree
// in preorder: each node is either a split (feature and threshold) or a leaf
// (its prediction).

#include <algorithm>
#include <array>
#include <fstream>
#include <memory>
#include <optional>
#include <print>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

constexpr std::array<const char*, 3> FEATURES = {"humidity", "pressure", "wind"};
constexpr int MAX_DEPTH = 3;
constexpr std::size_t MIN_SIZE = 5;

struct Day {
    std::array<double, FEATURES.size()> x;
    bool rain;
};

// One struct serves for both kinds of node; a leaf has no children. A
// std::unique_ptr owns the node it points to and deletes it when it goes out
// of scope, so dropping the root frees the whole tree with no free_tree.
// It can't be copied, only moved, so each node has exactly one owner.
struct Node {
    int feature = 0;
    double threshold = 0;
    std::unique_ptr<Node> left, right;
    bool rain = false;

    bool is_leaf() const { return left == nullptr; }
};

// A candidate split and its weighted impurity, before any children exist.
struct Candidate {
    double score;
    int feature;
    double threshold;
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

// The named column of a CSV file, as strings; the caller parses numbers.
std::vector<std::string> read_column(const std::string& path, const std::string& name) {
    std::ifstream file(path);
    std::string line;
    std::getline(file, line);
    std::vector<std::string> header = split(line);
    auto found = std::find(header.begin(), header.end(), name);
    if (found == header.end()) {
        throw std::runtime_error("no column " + name);
    }
    std::size_t index = found - header.begin();

    std::vector<std::string> values;
    while (std::getline(file, line)) {
        if (!line.empty()) {
            values.push_back(split(line).at(index));
        }
    }
    return values;
}

std::size_t count_yes(const std::vector<Day>& days) {
    // count_if counts the elements the lambda (an inline function) accepts.
    return std::ranges::count_if(days, [](const Day& d) { return d.rain; });
}

// The chance that two days drawn at random (with replacement) disagree.
double gini(const std::vector<Day>& days) {
    double p = static_cast<double>(count_yes(days)) / days.size();
    return 1 - p * p - (1 - p) * (1 - p);
}

// Rain only on a strict majority; an even split predicts no rain.
bool majority(const std::vector<Day>& days) {
    return 2 * count_yes(days) > days.size();
}

// The days at or below the threshold (left) or above it (right).
std::vector<Day> side(const std::vector<Day>& days, int f, double threshold, bool left) {
    std::vector<Day> out;
    for (const Day& d : days) {
        if ((d.x[f] <= threshold) == left) {
            out.push_back(d);
        }
    }
    return out;
}

// The candidate with the lowest weighted Gini impurity, or nothing
// (std::nullopt) if no feature has two distinct values. Features are tried in
// column order and thresholds from smallest to largest; only a strictly lower
// score replaces the best so far.
std::optional<Candidate> best_split(const std::vector<Day>& days) {
    std::optional<Candidate> best;
    for (int f = 0; f < static_cast<int>(FEATURES.size()); f++) {
        // A std::set keeps its values sorted and drops repeats.
        std::set<double> values;
        for (const Day& d : days) {
            values.insert(d.x[f]);
        }
        std::optional<double> previous;
        for (double value : values) {
            if (previous) {
                double t = (*previous + value) / 2;
                std::vector<Day> left = side(days, f, t, true);
                std::vector<Day> right = side(days, f, t, false);
                double score = (left.size() * gini(left) + right.size() * gini(right))
                    / days.size();
                if (!best || score < best->score) {
                    best = Candidate{score, f, t};
                }
            }
            previous = value;
        }
    }
    return best;
}

std::unique_ptr<Node> leaf(const std::vector<Day>& days) {
    auto node = std::make_unique<Node>();
    node->rain = majority(days);
    return node;
}

// Grow a tree on days, calling itself on each side of the best split.
std::unique_ptr<Node> grow(const std::vector<Day>& days, int depth) {
    double impurity = gini(days);
    if (impurity == 0 || days.size() < MIN_SIZE || depth == MAX_DEPTH) {
        return leaf(days);
    }
    std::optional<Candidate> best = best_split(days);
    if (!best || best->score >= impurity) {
        return leaf(days); // no split makes the sides purer
    }
    auto node = std::make_unique<Node>();
    node->feature = best->feature;
    node->threshold = best->threshold;
    node->left = grow(side(days, best->feature, best->threshold, true), depth + 1);
    node->right = grow(side(days, best->feature, best->threshold, false), depth + 1);
    return node;
}

bool predict(const Node& node, const Day& day) {
    const Node* n = &node;
    while (!n->is_leaf()) {
        n = day.x[n->feature] <= n->threshold ? n->left.get() : n->right.get();
    }
    return n->rain;
}

// Print every node, parents before children, left before right. k is the
// running node number and leaves the running leaf count, both passed by
// reference (&) so the calls below share them.
void print_preorder(const Node& node, int& k, int& leaves) {
    int id = ++k;
    if (node.is_leaf()) {
        std::println("node_{}_predict {}", id, node.rain ? "yes" : "no");
        leaves++;
        return;
    }
    std::println("node_{}_feature {}", id, FEATURES[node.feature]);
    std::println("node_{}_threshold {:.6f}", id, node.threshold);
    print_preorder(*node.left, k, leaves);
    print_preorder(*node.right, k, leaves);
}

std::size_t count_correct(const Node& tree, const std::vector<Day>& days) {
    return std::ranges::count_if(days, [&](const Day& d) { return predict(tree, d) == d.rain; });
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    std::array<std::vector<std::string>, FEATURES.size()> columns;
    for (std::size_t f = 0; f < FEATURES.size(); f++) {
        columns[f] = read_column(argv[1], FEATURES[f]);
    }
    std::vector<std::string> rain = read_column(argv[1], "rain");
    std::vector<std::string> split_name = read_column(argv[1], "split");

    std::vector<Day> train, test;
    for (std::size_t row = 0; row < rain.size(); row++) {
        Day day{};
        for (std::size_t f = 0; f < FEATURES.size(); f++) {
            day.x[f] = std::stod(columns[f][row]);
        }
        day.rain = rain[row] == "yes"; // std::string compares by content
        (split_name[row] == "train" ? train : test).push_back(day);
    }
    std::unique_ptr<Node> tree = grow(train, 0);

    std::println("train_count {}", train.size());
    std::println("test_count {}", test.size());
    int k = 0, leaves = 0;
    print_preorder(*tree, k, leaves);
    std::println("leaves {}", leaves);

    std::size_t correct = count_correct(*tree, test);
    std::println("train_accuracy {:.6f}",
                 static_cast<double>(count_correct(*tree, train)) / train.size());
    std::println("correct {}", correct);
    std::println("accuracy {:.6f}", static_cast<double>(correct) / test.size());
    // No cleanup: when tree goes out of scope, every node is deleted.
}
