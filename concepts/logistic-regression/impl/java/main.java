// Logistic regression by gradient descent, using only the Java standard
// library.
//
// Predicts whether a student passed from study hours and sleep. Each feature
// is rescaled with the training rows' mean and standard deviation, then the
// weights start at zero and take 1000 fixed steps of batch gradient descent
// on the average log-loss. The JDK has no regression or optimizer, so every
// step is a loop.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

class Main {
    static final double LEARNING_RATE = 0.5;
    static final int STEPS = 1000;

    // The named column of a CSV file's lines, as strings, since "split" holds
    // words; the caller parses the numbers.
    static String[] readColumn(List<String> lines, String name) {
        int index = Arrays.asList(lines.get(0).split(",")).indexOf(name);
        if (index < 0) {
            throw new IllegalArgumentException("no column " + name);
        }
        String[] values = new String[lines.size() - 1];
        for (int row = 1; row < lines.size(); row++) {
            values[row - 1] = lines.get(row).split(",")[index];
        }
        return values;
    }

    static double sigmoid(double z) {
        return 1 / (1 + Math.exp(-z));
    }

    static double dot(double[] u, double[] v) {
        double total = 0;
        for (int j = 0; j < u.length; j++) {
            total += u[j] * v[j];
        }
        return total;
    }

    // Reading a file can fail with an IOException, and Java makes us say so
    // with "throws".
    public static void main(String[] args) throws IOException {
        List<String> lines = Files.readAllLines(Path.of(args[0]));
        String[] hours = readColumn(lines, "hours");
        String[] sleep = readColumn(lines, "sleep");
        String[] passed = readColumn(lines, "passed");
        String[] split = readColumn(lines, "split");

        // Count the training rows first, since a Java array's length is
        // fixed when it is made.
        int n = 0;
        for (String s : split) {
            // == would compare the String objects, not their letters.
            if (s.equals("train")) n++;
        }
        int nTest = split.length - n;

        // Each row of x is {1, hours, sleep}; the leading 1 multiplies the
        // intercept. A double[][] is an array of row arrays.
        double[][] train = new double[n][];
        double[] y = new double[n];
        double[][] test = new double[nTest][];
        double[] yTest = new double[nTest];
        for (int i = 0, a = 0, b = 0; i < split.length; i++) {
            double[] x = {1, Double.parseDouble(hours[i]), Double.parseDouble(sleep[i])};
            if (split[i].equals("train")) {
                train[a] = x;
                y[a++] = Double.parseDouble(passed[i]);
            } else {
                test[b] = x;
                yTest[b++] = Double.parseDouble(passed[i]);
            }
        }

        // Scale each feature (columns 1 and 2) to mean 0 and (sample) standard
        // deviation 1, using the training rows only, then apply the same
        // shift and stretch to the test rows.
        for (int j = 1; j <= 2; j++) {
            double sum = 0;
            for (double[] x : train) sum += x[j];
            double mean = sum / n;
            double squares = 0;
            for (double[] x : train) squares += (x[j] - mean) * (x[j] - mean);
            double sd = Math.sqrt(squares / (n - 1));
            for (double[] x : train) x[j] = (x[j] - mean) / sd;
            for (double[] x : test) x[j] = (x[j] - mean) / sd;
        }

        // new double[3] starts at {0, 0, 0}: Java fills new arrays with zeros.
        double[] weights = new double[3];
        for (int step = 0; step < STEPS; step++) {
            // Gradient of the average log-loss: the mean of (p - y) times
            // each input, summed into its own array before any weight moves.
            double[] gradient = new double[3];
            for (int i = 0; i < n; i++) {
                double error = sigmoid(dot(weights, train[i])) - y[i];
                for (int j = 0; j < 3; j++) {
                    gradient[j] += error * train[i][j];
                }
            }
            for (int j = 0; j < 3; j++) {
                weights[j] -= LEARNING_RATE * gradient[j] / n;
            }
        }

        double logLoss = 0;
        for (int i = 0; i < n; i++) {
            double p = sigmoid(dot(weights, train[i]));
            logLoss -= y[i] * Math.log(p) + (1 - y[i]) * Math.log(1 - p);
        }
        logLoss /= n;

        int correct = 0;
        for (int i = 0; i < nTest; i++) {
            double predicted = sigmoid(dot(weights, test[i])) >= 0.5 ? 1 : 0;
            if (predicted == yTest[i]) correct++;
        }

        // printf follows the computer's language settings unless told
        // otherwise; Locale.ROOT keeps the decimal point a point.
        Locale root = Locale.ROOT;
        System.out.printf(root, "train_count %d%n", n);
        System.out.printf(root, "test_count %d%n", nTest);
        System.out.printf(root, "intercept %.6f%n", weights[0]);
        System.out.printf(root, "weight_hours %.6f%n", weights[1]);
        System.out.printf(root, "weight_sleep %.6f%n", weights[2]);
        System.out.printf(root, "log_loss %.6f%n", logLoss);
        System.out.printf(root, "correct %d%n", correct);
        // (double) converts before dividing; 37 / 50 between ints would be 0.
        System.out.printf(root, "accuracy %.6f%n", (double) correct / nTest);
    }
}
