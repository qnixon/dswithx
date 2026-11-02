// Descriptive statistics on one CSV column, using only the Java standard
// library.
//
// Every Java program lives in a class; the runner calls Main.main. Java's
// streams have average() and summaryStatistics(), which would give the mean,
// min, and max in one call, so we write those out.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

class Main {
    static final String COLUMN = "minutes";

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

    public static void main(String[] args) throws IOException {
        double[] values = readColumn(Path.of(args[0]), COLUMN);
        Arrays.sort(values);
        int n = values.length;

        double sum = 0;
        for (double value : values) {
            sum += value;
        }
        double mean = sum / n;

        // Arrays count from 0: for n = 120 the middle pair is at 59 and 60.
        // n / 2 divides two ints, so it rounds down to a whole number.
        double median = n % 2 == 1
            ? values[n / 2]
            : (values[n / 2 - 1] + values[n / 2]) / 2;

        // Sample variance divides by n - 1, not n (Bessel's correction).
        double squares = 0;
        for (double value : values) {
            squares += (value - mean) * (value - mean);
        }
        double variance = squares / (n - 1);

        // printf follows the computer's language settings unless told
        // otherwise; Locale.ROOT keeps the decimal point a point.
        Locale root = Locale.ROOT;
        System.out.printf(root, "count %d%n", n);
        System.out.printf(root, "sum %.6f%n", sum);
        System.out.printf(root, "mean %.6f%n", mean);
        System.out.printf(root, "median %.6f%n", median);
        System.out.printf(root, "min %.6f%n", values[0]);
        System.out.printf(root, "max %.6f%n", values[n - 1]);
        System.out.printf(root, "range %.6f%n", values[n - 1] - values[0]);
        System.out.printf(root, "variance %.6f%n", variance);
        System.out.printf(root, "std_dev %.6f%n", Math.sqrt(variance));
    }
}
