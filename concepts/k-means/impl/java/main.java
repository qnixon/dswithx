// k-means clustering (Lloyd's algorithm), using only the Java standard
// library.
//
// Starts from the first K points as centroids, then alternates two steps
// until no point changes cluster: assign each point to its nearest centroid,
// and move each centroid to the mean of its points.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

class Main {
    static final int K = 3;
    static final int MAX_ITERATIONS = 100;

    // A record is a small immutable class: Java writes the constructor, the
    // x() and y() accessors, and equals for us.
    record Point(double x, double y) {}

    // The named column of a CSV file, as an array of doubles. Reading a file
    // can fail with an IOException, and Java makes us say so with "throws".
    static double[] readColumn(Path path, String name) throws IOException {
        List<String> lines = Files.readAllLines(path);
        int index = Arrays.asList(lines.get(0).split(",")).indexOf(name);
        if (index < 0) {
            throw new IllegalArgumentException("no column " + name);
        }
        double[] values = new double[lines.size() - 1];
        for (int row = 1; row < lines.size(); row++) {
            values[row - 1] = Double.parseDouble(lines.get(row).split(",")[index]);
        }
        return values;
    }

    static double distance(Point a, Point b) {
        return Math.hypot(a.x() - b.x(), a.y() - b.y());
    }

    // The index of the closest centroid. The comparison is strict, so a tie
    // goes to the lower index.
    static int nearest(Point p, Point[] centroids) {
        int best = 0;
        for (int j = 1; j < centroids.length; j++) {
            if (distance(p, centroids[j]) < distance(p, centroids[best])) {
                best = j;
            }
        }
        return best;
    }

    public static void main(String[] args) throws IOException {
        Path path = Path.of(args[0]);
        double[] xs = readColumn(path, "x");
        double[] ys = readColumn(path, "y");
        var points = new Point[xs.length];
        for (int i = 0; i < points.length; i++) {
            points[i] = new Point(xs[i], ys[i]);
        }

        // Records can't be changed, so moving a centroid replaces it in this
        // array and never touches the points.
        Point[] centroids = Arrays.copyOf(points, K);
        int[] assignment = null; // nothing assigned before the first pass
        int iterations = 0;
        while (iterations < MAX_ITERATIONS) {
            iterations++;
            var newAssignment = new int[points.length];
            for (int i = 0; i < points.length; i++) {
                newAssignment[i] = nearest(points[i], centroids);
            }
            // Arrays.equals compares the contents; == would only ask whether
            // both names point at the same array. Against null it is false.
            if (Arrays.equals(newAssignment, assignment)) {
                break;
            }
            assignment = newAssignment;

            var sumX = new double[K];
            var sumY = new double[K];
            var counts = new int[K];
            for (int i = 0; i < points.length; i++) {
                int j = assignment[i];
                sumX[j] += points[i].x();
                sumY[j] += points[i].y();
                counts[j]++;
            }
            for (int j = 0; j < K; j++) {
                if (counts[j] > 0) { // an empty cluster keeps its old centroid
                    centroids[j] = new Point(sumX[j] / counts[j], sumY[j] / counts[j]);
                }
            }
        }

        var sizes = new int[K];
        double inertia = 0;
        for (int i = 0; i < points.length; i++) {
            int j = assignment[i];
            sizes[j]++;
            double d = distance(points[i], centroids[j]);
            inertia += d * d;
        }

        // printf follows the computer's language settings unless told
        // otherwise; Locale.ROOT keeps the decimal point a point.
        Locale root = Locale.ROOT;
        System.out.printf(root, "iterations %d%n", iterations);
        for (int j = 0; j < K; j++) {
            System.out.printf(root, "centroid_%d_x %.6f%n", j + 1, centroids[j].x());
            System.out.printf(root, "centroid_%d_y %.6f%n", j + 1, centroids[j].y());
        }
        for (int j = 0; j < K; j++) {
            System.out.printf(root, "size_%d %d%n", j + 1, sizes[j]);
        }
        System.out.printf(root, "inertia %.6f%n", inertia);
    }
}
