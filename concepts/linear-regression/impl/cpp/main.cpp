// Simple linear regression by least squares, using only the C++ standard
// library.
//
// Fits score = intercept + slope * hours. C++ has no regression or
// correlation function to avoid. std::accumulate and std::inner_product do
// the sums.

#include <algorithm>
#include <cmath>
#include <fstream>
#include <numeric>
#include <print>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

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

// The named column of a CSV file, as numbers. A vector grows as we
// push_back, so there's no need to know the row count first.
std::vector<double> read_column(const std::string& path, const std::string& name) {
    std::ifstream file(path);
    std::string line;
    std::getline(file, line);
    std::vector<std::string> header = split(line);
    auto found = std::find(header.begin(), header.end(), name);
    if (found == header.end()) {
        throw std::runtime_error("no column " + name);
    }
    std::size_t index = found - header.begin();

    std::vector<double> values;
    while (std::getline(file, line)) {
        if (!line.empty()) {
            values.push_back(std::stod(split(line).at(index)));
        }
    }
    return values;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    // Each column is read on its own; row i of the file is xs[i] and ys[i].
    std::vector<double> xs = read_column(argv[1], "hours");
    std::vector<double> ys = read_column(argv[1], "score");
    if (xs.size() != ys.size()) {
        throw std::runtime_error("columns differ in length");
    }
    std::size_t n = xs.size();

    // First pass: the means. The 0.0 makes accumulate add doubles.
    double mean_x = std::accumulate(xs.begin(), xs.end(), 0.0) / n;
    double mean_y = std::accumulate(ys.begin(), ys.end(), 0.0) / n;

    // Second pass: deviations from the means. A lambda subtracts the mean
    // from every value, and std::ranges::transform writes the results.
    auto deviations = [](const std::vector<double>& values, double mean) {
        std::vector<double> result(values.size());
        std::ranges::transform(values, result.begin(),
                               [mean](double value) { return value - mean; });
        return result;
    };
    std::vector<double> dx = deviations(xs, mean_x);
    std::vector<double> dy = deviations(ys, mean_y);

    // inner_product walks two ranges side by side and adds up a[i] * b[i]:
    // the sums of squares and of cross-products.
    double sxx = std::inner_product(dx.begin(), dx.end(), dx.begin(), 0.0);
    double syy = std::inner_product(dy.begin(), dy.end(), dy.begin(), 0.0);
    double sxy = std::inner_product(dx.begin(), dx.end(), dy.begin(), 0.0);

    double slope = sxy / sxx;
    double intercept = mean_y - slope * mean_x;
    double r = sxy / std::sqrt(sxx * syy);

    std::println("count {}", n);
    std::println("slope {:.6f}", slope);
    std::println("intercept {:.6f}", intercept);
    std::println("r {:.6f}", r);
    std::println("r_squared {:.6f}", r * r);
}
