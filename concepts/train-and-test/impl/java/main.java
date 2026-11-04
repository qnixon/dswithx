// Train and test error for polynomials of degree 1 to 8, using only the Java
// standard library.
//
// Each polynomial is fitted by least squares to the training drives only: we
// build the normal equations and solve them by Gaussian elimination. Then we
// measure its root-mean-square error on the training drives and on the test
// drives it never saw.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.function.DoubleUnaryOperator;

class Main {
    static final int MAX_DEGREE = 8;

    // A record is a small immutable class; Java writes its constructor and
    // accessors, so a point's speed is p.x().
    record Point(double x, double y) {}

    // Solve a x = b by Gaussian elimination with partial pivoting.
    static double[] solve(double[][] a, double[] b) {
        int n = b.length;
        double[][] m = new double[n][];
        for (int i = 0; i < n; i++) {
            m[i] = Arrays.copyOf(a[i], n + 1);  // the row, plus room for b
            m[i][n] = b[i];
        }
        for (int col = 0; col < n; col++) {
            // Swap up the row with the largest entry in this column, which
            // keeps the rounding error small. A double[][] is an array of row
            // arrays, so the swap moves two references, not the entries.
            int pivot = col;
            for (int r = col + 1; r < n; r++) {
                if (Math.abs(m[r][col]) > Math.abs(m[pivot][col])) {
                    pivot = r;
                }
            }
            double[] row = m[col];
            m[col] = m[pivot];
            m[pivot] = row;
            for (int r = col + 1; r < n; r++) {
                double factor = m[r][col] / m[col][col];
                for (int c = col; c <= n; c++) {
                    m[r][c] -= factor * m[col][c];
                }
            }
        }
        // Back substitution, from the last unknown up.
        double[] x = new double[n];
        for (int r = n - 1; r >= 0; r--) {
            double s = m[r][n];
            for (int c = r + 1; c < n; c++) {
                s -= m[r][c] * x[c];
            }
            x[r] = s / m[r][r];
        }
        return x;
    }

    // Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i
    // of Z is 1, z_i, z_i^2, ..., z_i^degree.
    static double[] fit(List<Point> points, int degree, DoubleUnaryOperator scale) {
        int size = degree + 1;
        double[][] a = new double[size][size];  // new arrays start at 0.0
        double[] b = new double[size];
        for (Point p : points) {
            double z = scale.applyAsDouble(p.x());
            for (int i = 0; i < size; i++) {
                b[i] += p.y() * Math.pow(z, i);
                for (int j = 0; j < size; j++) {
                    a[i][j] += Math.pow(z, i + j);
                }
            }
        }
        return solve(a, b);
    }

    static double rmse(double[] coefs, List<Point> points, DoubleUnaryOperator scale) {
        double total = 0;
        for (Point p : points) {
            double z = scale.applyAsDouble(p.x());
            double predicted = 0;
            for (int i = 0; i < coefs.length; i++) {
                predicted += coefs[i] * Math.pow(z, i);
            }
            total += (predicted - p.y()) * (predicted - p.y());
        }
        return Math.sqrt(total / points.size());
    }

    // Reading a file can fail with an IOException, and Java makes us say so
    // with "throws".
    public static void main(String[] args) throws IOException {
        List<String> lines = Files.readAllLines(Path.of(args[0]));
        List<String> header = Arrays.asList(lines.get(0).split(","));
        int speed = header.indexOf("speed");
        int litres = header.indexOf("litres");
        int split = header.indexOf("split");

        List<Point> train = new ArrayList<>();
        List<Point> test = new ArrayList<>();
        for (String line : lines.subList(1, lines.size())) {
            if (line.isBlank()) {
                continue;
            }
            String[] fields = line.split(",");
            Point p = new Point(Double.parseDouble(fields[speed]), Double.parseDouble(fields[litres]));
            (fields[split].equals("train") ? train : test).add(p);
        }

        // Map the training speeds onto -1 to 1. Raw speeds to the 16th power
        // (the largest entry at degree 8) would swamp the small ones and make
        // the equations hard to solve accurately.
        double low = train.stream().mapToDouble(Point::x).min().orElseThrow();
        double high = train.stream().mapToDouble(Point::x).max().orElseThrow();
        double mid = (low + high) / 2;
        double half = (high - low) / 2;
        DoubleUnaryOperator scale = x -> (x - mid) / half;

        double[] trainError = new double[MAX_DEGREE + 1];
        double[] testError = new double[MAX_DEGREE + 1];
        for (int d = 1; d <= MAX_DEGREE; d++) {
            double[] coefs = fit(train, d, scale);
            trainError[d] = rmse(coefs, train, scale);
            testError[d] = rmse(coefs, test, scale);
        }

        // printf follows the computer's language settings unless told
        // otherwise; Locale.ROOT keeps the decimal point a point.
        Locale root = Locale.ROOT;
        System.out.printf(root, "train_count %d%n", train.size());
        System.out.printf(root, "test_count %d%n", test.size());
        for (int d = 1; d <= MAX_DEGREE; d++) {
            System.out.printf(root, "train_rmse_d%d %.6f%n", d, trainError[d]);
        }
        for (int d = 1; d <= MAX_DEGREE; d++) {
            System.out.printf(root, "test_rmse_d%d %.6f%n", d, testError[d]);
        }
    }
}
