// Logistic regression by gradient descent, using only the C++ standard
// library.
//
// Predicts whether a student passed from study hours and sleep. Each feature
// is rescaled with the training rows' mean and standard deviation, then the
// weights start at zero and take 1,000 steps of batch gradient descent on the
// average log-loss. C++ has no regression routine, so every step is a loop.

#include <algorithm>
#include <array>
#include <cmath>
#include <fstream>
#include <numeric>
#include <print>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

constexpr std::size_t K = 3;  // inputs per row: 1 (for the intercept), hours, sleep
constexpr double LEARNING_RATE = 0.5;
constexpr int STEPS = 1000;

// std::array has its length in its type, so Inputs is always exactly three
// doubles, and unlike a C array it can be copied, assigned, and returned.
using Inputs = std::array<double, K>;

// One student: x[0] is always 1, so weight 0 acts as the intercept.
struct Example {
    Inputs x;
    int y;
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

// The 0-based position of the named column in the header.
std::size_t column(const std::vector<std::string>& header, const std::string& name) {
    auto found = std::find(header.begin(), header.end(), name);
    if (found == header.end()) {
        throw std::runtime_error("no column " + name);
    }
    return found - header.begin();
}

// Read the CSV into training and test rows, sorted by the "split" column,
// which holds text rather than a number.
void read_rows(const std::string& path, std::vector<Example>& train, std::vector<Example>& test) {
    std::ifstream file(path);
    std::string line;
    std::getline(file, line);
    std::vector<std::string> header = split(line);
    std::size_t hours = column(header, "hours"), sleep = column(header, "sleep");
    std::size_t passed = column(header, "passed"), which = column(header, "split");

    while (std::getline(file, line)) {
        if (line.empty()) {
            continue;
        }
        std::vector<std::string> fields = split(line);
        Example row{{1.0, std::stod(fields.at(hours)), std::stod(fields.at(sleep))},
                    std::stoi(fields.at(passed))};
        (fields.at(which) == "train" ? train : test).push_back(row);
    }
}

double sigmoid(double z) { return 1 / (1 + std::exp(-z)); }

// The probability of passing: the sigmoid of the weighted sum of inputs.
// inner_product multiplies the two arrays entry by entry and adds, starting
// from 0.0 so that it adds doubles.
double predict(const Inputs& w, const Inputs& x) {
    return sigmoid(std::inner_product(w.begin(), w.end(), x.begin(), 0.0));
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    std::vector<Example> train, test;
    read_rows(argv[1], train, test);
    std::size_t n = train.size();

    // Scale each feature to mean 0 and (sample) standard deviation 1, using
    // the training rows only, then apply the same shift to the test rows.
    // Column 0 holds the ones, so the features are columns 1 and 2. The &
    // in "Example& row" makes row a reference, so the loop changes the
    // stored rows rather than copies of them.
    for (std::size_t j = 1; j < K; j++) {
        double total = 0.0;
        for (const Example& row : train) total += row.x[j];
        double mean = total / n;
        double squares = 0.0;
        for (const Example& row : train) squares += (row.x[j] - mean) * (row.x[j] - mean);
        double sd = std::sqrt(squares / (n - 1));
        for (Example& row : train) row.x[j] = (row.x[j] - mean) / sd;
        for (Example& row : test) row.x[j] = (row.x[j] - mean) / sd;
    }

    // Braces with nothing inside set every entry to zero.
    Inputs w{};
    for (int step = 0; step < STEPS; step++) {
        // Gradient of the average log-loss: the mean of (p - y) times each
        // input. It is summed over every student before any weight moves.
        Inputs gradient{};
        for (const Example& row : train) {
            double error = predict(w, row.x) - row.y;
            for (std::size_t j = 0; j < K; j++) gradient[j] += error * row.x[j];
        }
        for (std::size_t j = 0; j < K; j++) w[j] -= LEARNING_RATE * gradient[j] / n;
    }

    double loss = 0.0;
    for (const Example& row : train) {
        double p = predict(w, row.x);
        loss -= row.y == 1 ? std::log(p) : std::log(1 - p);
    }
    loss /= n;

    int correct = 0;
    for (const Example& row : test) {
        int guess = predict(w, row.x) >= 0.5 ? 1 : 0;
        if (guess == row.y) correct++;
    }

    std::println("train_count {}", n);
    std::println("test_count {}", test.size());
    std::println("intercept {:.6f}", w[0]);
    std::println("weight_hours {:.6f}", w[1]);
    std::println("weight_sleep {:.6f}", w[2]);
    std::println("log_loss {:.6f}", loss);
    std::println("correct {}", correct);
    // Convert before dividing, or 37 / 50 is integer division and gives 0.
    std::println("accuracy {:.6f}", static_cast<double>(correct) / test.size());
}
