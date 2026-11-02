// k-means clustering (Lloyd's algorithm), using only the C++ standard library.
//
// Starts from the first K points as centroids, then alternates two steps until
// no point changes cluster: assign each point to its nearest centroid, and move
// each centroid to the mean of its points.

#include <algorithm>
#include <cstddef>
#include <fstream>
#include <print>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

constexpr std::size_t K = 3;
constexpr int MAX_ITERATIONS = 100;

// A struct groups the two coordinates, so a point can be copied with =.
struct Point {
    double x;
    double y;
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

// The x and y columns of a CSV file, found by name, as points.
std::vector<Point> read_points(const std::string& path) {
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
    std::size_t x_col = column("x");
    std::size_t y_col = column("y");

    std::vector<Point> points;
    while (std::getline(file, line)) {
        if (!line.empty()) {
            std::vector<std::string> fields = split(line);
            points.push_back({std::stod(fields.at(x_col)), std::stod(fields.at(y_col))});
        }
    }
    return points;
}

// Squared Euclidean distance. It ranks centroids in the same order as the
// distance itself, so the nearest one needs no sqrt.
double squared_distance(Point a, Point b) {
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
}

// The index of the closest centroid. std::min_element returns the first of
// equal smallest values, so a tie goes to the lower index.
std::size_t nearest(Point p, const std::vector<Point>& centroids) {
    auto closer = [p](Point a, Point b) {
        return squared_distance(p, a) < squared_distance(p, b);
    };
    auto best = std::min_element(centroids.begin(), centroids.end(), closer);
    return best - centroids.begin();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::println(stderr, "usage: program data.csv");
        return 1;
    }
    std::vector<Point> points = read_points(argv[1]);
    if (points.size() < K) {
        std::println(stderr, "need at least {} points", K);
        return 1;
    }

    // This constructor copies the first K points, so moving a centroid
    // never changes a data point.
    std::vector<Point> centroids(points.begin(), points.begin() + K);
    // Empty until the first pass, so that pass never matches it.
    std::vector<std::size_t> assignment;

    int iterations = 0;
    while (iterations < MAX_ITERATIONS) {
        iterations++;
        std::vector<std::size_t> new_assignment;
        for (Point p : points) {
            new_assignment.push_back(nearest(p, centroids));
        }
        // == on two vectors compares their lengths and then every element.
        if (new_assignment == assignment) {
            break;   // this unchanged pass still counts
        }
        assignment = new_assignment;

        // Sum each cluster's points in one pass, then divide by its size.
        std::vector<Point> sums(K, Point{0.0, 0.0});
        std::vector<int> sizes(K, 0);
        for (std::size_t i = 0; i < points.size(); i++) {
            sums[assignment[i]].x += points[i].x;
            sums[assignment[i]].y += points[i].y;
            sizes[assignment[i]]++;
        }
        for (std::size_t j = 0; j < K; j++) {
            if (sizes[j] > 0) {   // an empty cluster keeps its old centroid
                centroids[j] = {sums[j].x / sizes[j], sums[j].y / sizes[j]};
            }
        }
    }

    std::vector<int> sizes(K, 0);
    double inertia = 0.0;
    for (std::size_t i = 0; i < points.size(); i++) {
        sizes[assignment[i]]++;
        inertia += squared_distance(points[i], centroids[assignment[i]]);
    }

    // Clusters are numbered from 0 inside C++ and from 1 in the output.
    std::println("iterations {}", iterations);
    for (std::size_t j = 0; j < K; j++) {
        std::println("centroid_{}_x {:.6f}", j + 1, centroids[j].x);
        std::println("centroid_{}_y {:.6f}", j + 1, centroids[j].y);
    }
    for (std::size_t j = 0; j < K; j++) {
        std::println("size_{} {}", j + 1, sizes[j]);
    }
    std::println("inertia {:.6f}", inertia);
}
