// Principal component analysis by power iteration, using only the C++
// standard library.
//
// Standardizes the four scores, builds their correlation matrix, and finds
// the top two eigenvectors (the principal components): power iteration finds
// the first, then deflation removes it from the matrix so the same steps
// find the second. C++ has no matrix type and no eigenvalue routine.

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

constexpr std::size_t K = 4;  // subjects
constexpr int STEPS = 1000;
const std::array<std::string, K> SUBJECTS = {"math", "physics", "reading", "writing"};

// The size of a std::array is part of its type, so the compiler knows a
// Matrix is 4 by 4. Unlike a C array, a std::array can be returned from a
// function, and assigning one copies every entry.
using Vector = std::array<double, K>;
using Matrix = std::array<Vector, K>;

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

// The four subject columns, found by name, as rows of four scores.
std::vector<Vector> read_scores(const std::string& path) {
    std::ifstream file(path);
    std::string line;
    std::getline(file, line);
    std::vector<std::string> header = split(line);
    std::array<std::size_t, K> cols;
    for (std::size_t j = 0; j < K; j++) {
        auto found = std::find(header.begin(), header.end(), SUBJECTS[j]);
        if (found == header.end()) {
            throw std::runtime_error("no column " + SUBJECTS[j]);
        }
        cols[j] = found - header.begin();
    }

    std::vector<Vector> rows;
    while (std::getline(file, line)) {
        if (line.empty()) {
            continue;
        }
        std::vector<std::string> fields = split(line);
        Vector row;
        for (std::size_t j = 0; j < K; j++) row[j] = std::stod(fields.at(cols[j]));
        rows.push_back(row);
    }
    return rows;
}

// inner_product multiplies two ranges entry by entry and adds; the 0.0
// makes it add doubles.
double dot(const Vector& u, const Vector& v) {
    return std::inner_product(u.begin(), u.end(), v.begin(), 0.0);
}

// m v: each entry is one row of m dotted with v.
Vector mat_vec(const Matrix& m, const Vector& v) {
    Vector out;
    for (std::size_t i = 0; i < K; i++) out[i] = dot(m[i], v);
    return out;
}

// Power iteration: multiply by the matrix and rescale, STEPS times. Fills
// v with the eigenvector and returns its eigenvalue.
double top_eigenvector(const Matrix& m, Vector& v) {
    v = {1, 0, 0, 0};
    for (int step = 0; step < STEPS; step++) {
        Vector mv = mat_vec(m, v);
        double length = std::sqrt(dot(mv, mv));
        for (std::size_t i = 0; i < K; i++) v[i] = mv[i] / length;
    }
    // An eigenvector can point either way; make its first entry positive.
    if (v[0] < 0) {
        for (double& x : v) x = -x;
    }
    return dot(v, mat_vec(m, v));  // the Rayleigh quotient v . (m v)
}

void report(int c, double value, const Vector& pc) {
    std::println("eigenvalue_{} {:.6f}", c, value);
    // Standardized columns each have variance 1, so the total is K.
    std::println("explained_{} {:.6f}", c, value / K);
    for (std::size_t j = 0; j < K; j++) {
        std::println("pc{}_{} {:.6f}", c, SUBJECTS[j], pc[j]);
    }
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    std::vector<Vector> z = read_scores(argv[1]);
    std::size_t n = z.size();

    // Standardize each column to mean 0 and (sample) standard deviation 1.
    // The & makes row a reference, so the last loop changes z itself.
    for (std::size_t j = 0; j < K; j++) {
        double total = 0.0;
        for (const Vector& row : z) total += row[j];
        double mean = total / n;
        double squares = 0.0;
        for (const Vector& row : z) squares += (row[j] - mean) * (row[j] - mean);
        double sd = std::sqrt(squares / (n - 1));
        for (Vector& row : z) row[j] = (row[j] - mean) / sd;
    }

    // The correlation matrix: the covariance of the standardized columns.
    Matrix corr;
    for (std::size_t a = 0; a < K; a++) {
        for (std::size_t b = 0; b < K; b++) {
            double total = 0.0;
            for (const Vector& row : z) total += row[a] * row[b];
            corr[a][b] = total / (n - 1);
        }
    }

    Vector pc_1, pc_2;
    double value_1 = top_eigenvector(corr, pc_1);
    // Deflation: subtract the first component's share, leaving the rest.
    // Assigning a std::array copies all 16 entries, so changing deflated
    // leaves corr as it was.
    Matrix deflated = corr;
    for (std::size_t a = 0; a < K; a++) {
        for (std::size_t b = 0; b < K; b++) deflated[a][b] -= value_1 * pc_1[a] * pc_1[b];
    }
    double value_2 = top_eigenvector(deflated, pc_2);

    std::println("count {}", n);
    report(1, value_1, pc_1);
    report(2, value_2, pc_2);
    // Vectors count from 0, so the first student is z[0].
    std::println("student_1_pc1 {:.6f}", dot(z[0], pc_1));
    std::println("student_1_pc2 {:.6f}", dot(z[0], pc_2));
}
