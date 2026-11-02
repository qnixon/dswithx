// Simple linear regression by least squares, using only the Java standard
// library.
//
// Fits score = intercept + slope * hours. Java's streams have average(),
// which would give each mean in one call; we write the sums out instead, so
// the formulas stay visible.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

class Main {
    static final String X = "hours", Y = "score";

    // The named column of a CSV file's lines, as an array of doubles.
    static double[] readColumn(List<String> lines, String name) {
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

    static double mean(double[] values) {
        double sum = 0;
        for (double value : values) {
            sum += value;
        }
        return sum / values.length;
    }

    // Reading a file can fail with an IOException, and Java makes us say so
    // with "throws".
    public static void main(String[] args) throws IOException {
        List<String> lines = Files.readAllLines(Path.of(args[0]));
        // Both columns come from the same rows, so xs[i] and ys[i] belong to
        // the same student.
        double[] xs = readColumn(lines, X);
        double[] ys = readColumn(lines, Y);
        int n = xs.length;

        double meanX = mean(xs), meanY = mean(ys);

        // Sums of squared deviations and of cross-products, in one pass.
        double sxx = 0, syy = 0, sxy = 0;
        for (int i = 0; i < n; i++) {
            double dx = xs[i] - meanX, dy = ys[i] - meanY;
            sxx += dx * dx;
            syy += dy * dy;
            sxy += dx * dy;
        }

        double slope = sxy / sxx;
        double intercept = meanY - slope * meanX;
        double r = sxy / Math.sqrt(sxx * syy);

        // Locale.ROOT keeps the decimal point a point on any computer.
        Locale root = Locale.ROOT;
        System.out.printf(root, "count %d%n", n);
        System.out.printf(root, "slope %.6f%n", slope);
        System.out.printf(root, "intercept %.6f%n", intercept);
        System.out.printf(root, "r %.6f%n", r);
        System.out.printf(root, "r_squared %.6f%n", r * r);
    }
}
