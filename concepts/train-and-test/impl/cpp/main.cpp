// Train and test error for polynomials of degree 1 to 8, using only the C++
// standard library.
//
// Each polynomial is fitted by least squares to the training drives only:
// we build the normal equations and solve them by Gaussian elimination.
// Then we measure its root-mean-square error on the training drives and on
// the test drives it never saw.

#include <algorithm>
#include <cmath>
#include <fstream>
#include <functional>
#include <print>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

constexpr int MAX_DEGREE = 8;

struct Point {
    double x;  // speed
    double y;  // litres
};

// Each row of a Matrix is its own vector, so rows can differ in length and
// be swapped as whole objects.
using Vector = std::vector<double>;
using Matrix = std::vector<Vector>;

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

// The position of a named column in the header.
std::size_t column(const std::vector<std::string>& header, const std::string& name) {
    auto found = std::find(header.begin(), header.end(), name);
    if (found == header.end()) {
        throw std::runtime_error("no column " + name);
    }
    return found - header.begin();
}

// Sort the rows into training and test points by their split column.
void read(const std::string& path, std::vector<Point>& train, std::vector<Point>& test) {
    std::ifstream file(path);
    std::string line;
    std::getline(file, line);
    if (!line.empty() && line.back() == '\r') line.pop_back();
    std::vector<std::string> header = split(line);
    std::size_t speed = column(header, "speed");
    std::size_t litres = column(header, "litres");
    std::size_t split_col = column(header, "split");

    while (std::getline(file, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty()) {
            continue;
        }
        std::vector<std::string> fields = split(line);
        Point p{std::stod(fields.at(speed)), std::stod(fields.at(litres))};
        (fields.at(split_col) == "train" ? train : test).push_back(p);
    }
}

// Solve a x = b by Gaussian elimination with partial pivoting.
Vector solve(Matrix a, const Vector& b) {
    std::size_t n = b.size();
    for (std::size_t i = 0; i < n; i++) a[i].push_back(b[i]);  // augmented matrix
    for (std::size_t col = 0; col < n; col++) {
        // Swap up the row with the largest entry in this column, which keeps
        // the rounding error small. Swapping two vectors only trades their
        // internal pointers; no entries are copied.
        std::size_t pivot = col;
        for (std::size_t r = col + 1; r < n; r++) {
            if (std::abs(a[r][col]) > std::abs(a[pivot][col])) pivot = r;
        }
        std::swap(a[col], a[pivot]);
        for (std::size_t r = col + 1; r < n; r++) {
            double factor = a[r][col] / a[col][col];
            for (std::size_t c = col; c <= n; c++) a[r][c] -= factor * a[col][c];
        }
    }
    // Back substitution, from the last unknown up.
    Vector x(n, 0.0);
    for (std::size_t r = n; r-- > 0;) {
        double s = a[r][n];
        for (std::size_t c = r + 1; c < n; c++) s -= a[r][c] * x[c];
        x[r] = s / a[r][r];
    }
    return x;
}

// Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
// Z is 1, z_i, z_i^2, ..., z_i^degree.
Vector fit(const std::vector<Point>& points, int degree,
           const std::function<double(double)>& scale) {
    std::size_t size = degree + 1;
    Matrix a(size, Vector(size, 0.0));
    Vector b(size, 0.0);
    for (const Point& p : points) {
        double z = scale(p.x);
        for (std::size_t i = 0; i < size; i++) {
            b[i] += p.y * std::pow(z, i);
            for (std::size_t j = 0; j < size; j++) a[i][j] += std::pow(z, i + j);
        }
    }
    return solve(a, b);
}

double rmse(const Vector& coefs, const std::vector<Point>& points,
            const std::function<double(double)>& scale) {
    double total = 0.0;
    for (const Point& p : points) {
        double z = scale(p.x), predicted = 0.0;
        for (std::size_t i = 0; i < coefs.size(); i++) predicted += coefs[i] * std::pow(z, i);
        total += (predicted - p.y) * (predicted - p.y);
    }
    return std::sqrt(total / points.size());
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    std::vector<Point> train, test;
    read(argv[1], train, test);

    // Map the training speeds onto -1 to 1. Raw speeds to the 16th power
    // (the largest entry at degree 8) would swamp the small ones and make
    // the equations hard to solve accurately. minmax_element finds both
    // ends in one pass.
    auto [low, high] = std::minmax_element(
        train.begin(), train.end(), [](const Point& p, const Point& q) { return p.x < q.x; });
    double mid = (low->x + high->x) / 2, half = (high->x - low->x) / 2;
    auto scale = [mid, half](double x) { return (x - mid) / half; };

    std::println("train_count {}", train.size());
    std::println("test_count {}", test.size());
    std::vector<std::pair<double, double>> errors;
    for (int degree = 1; degree <= MAX_DEGREE; degree++) {
        Vector coefs = fit(train, degree, scale);
        errors.emplace_back(rmse(coefs, train, scale), rmse(coefs, test, scale));
    }
    for (int d = 1; d <= MAX_DEGREE; d++) {
        std::println("train_rmse_d{} {:.6f}", d, errors[d - 1].first);
    }
    for (int d = 1; d <= MAX_DEGREE; d++) {
        std::println("test_rmse_d{} {:.6f}", d, errors[d - 1].second);
    }
    return 0;
}
