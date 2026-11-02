// Descriptive statistics on one CSV column, using only the C++ standard
// library.
//
// C++ has no mean, median, or variance. It does have std::accumulate, which
// adds up a range, and std::sort, so those do the general work here.

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
    std::vector<double> values = read_column(argv[1], "minutes");
    std::sort(values.begin(), values.end());

    // size() is an unsigned std::size_t; n keeps it, and every division
    // below has a double on one side, so none of them rounds to a whole number.
    std::size_t n = values.size();
    // The 0.0 makes accumulate add doubles. A plain 0 would make it add
    // ints, cutting off the fraction at every step, and no warning says so.
    double sum = std::accumulate(values.begin(), values.end(), 0.0);
    double mean = sum / n;

    // Vectors count from 0: for n = 120 the middle pair is at 59 and 60.
    double median = n % 2 == 1
        ? values[n / 2]
        : (values[n / 2 - 1] + values[n / 2]) / 2;

    // Sample variance divides by n - 1, not n (Bessel's correction).
    double squares = 0.0;
    for (double value : values) {
        squares += (value - mean) * (value - mean);
    }
    double variance = squares / (n - 1);

    std::println("count {}", n);
    std::println("sum {:.6f}", sum);
    std::println("mean {:.6f}", mean);
    std::println("median {:.6f}", median);
    std::println("min {:.6f}", values.front());
    std::println("max {:.6f}", values.back());
    std::println("range {:.6f}", values.back() - values.front());
    std::println("variance {:.6f}", variance);
    std::println("std_dev {:.6f}", std::sqrt(variance));
}
