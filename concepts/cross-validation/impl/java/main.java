// 5-fold cross-validation for k-nearest neighbors, using only the Java
// standard library.
//
// Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
// holding out one fold at a time, picks the k with the best average
// accuracy, and then scores that k once on the untouched test seeds.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

class Main {
    static final int FOLDS = 5;

    // A record is a small class that holds values: Java writes its
    // constructor, its accessors (seed.length()), equals, and toString.
    record Seed(double length, double width, String variety) {}

    record Neighbor(double distance, String variety) {}

    // The named column of a CSV file's lines, as text. Numbers are parsed by
    // the caller, since the variety and split columns are words.
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

    static String classify(Seed point, List<Seed> train, int k) {
        List<Neighbor> neighbors = new ArrayList<>();
        for (Seed seed : train) {
            // Math.hypot(dx, dy) is the straight-line distance, sqrt(dx*dx + dy*dy).
            double d = Math.hypot(point.length() - seed.length(), point.width() - seed.width());
            neighbors.add(new Neighbor(d, seed.variety()));
        }
        // List.sort is stable, so equal distances keep file order.
        neighbors.sort(Comparator.comparingDouble(Neighbor::distance));

        // Count the votes of the k nearest: groupingBy makes a map from each
        // variety to how many neighbors have it.
        Map<String, Long> votes = neighbors.subList(0, k).stream()
            .collect(Collectors.groupingBy(Neighbor::variety, Collectors.counting()));

        // With two varieties and an odd k, the vote can't tie.
        String winner = null;
        for (var vote : votes.entrySet()) {
            if (winner == null || vote.getValue() > votes.get(winner)) {
                winner = vote.getKey();
            }
        }
        return winner;
    }

    static int countCorrect(List<Seed> points, List<Seed> train, int k) {
        int correct = 0;
        for (Seed seed : points) {
            // Strings are compared with equals; == would compare objects.
            if (classify(seed, train, k).equals(seed.variety())) {
                correct++;
            }
        }
        return correct;
    }

    static double cvAccuracy(List<Seed> train, int k) {
        // Fold f is rows f*size up to (f+1)*size. The rows are already
        // shuffled, so consecutive blocks make fair folds.
        int size = train.size() / FOLDS;
        int correct = 0;
        for (int f = 0; f < FOLDS; f++) {
            int start = f * size, end = (f + 1) * size;
            // subList is a view of train's rows, not a copy; rest is a new
            // list that copies the rows before and after the held-out block.
            List<Seed> heldOut = train.subList(start, end);
            List<Seed> rest = new ArrayList<>(train.subList(0, start));
            rest.addAll(train.subList(end, train.size()));
            correct += countCorrect(heldOut, rest, k);
        }
        return (double) correct / train.size();
    }

    // Reading a file can fail with an IOException, and Java makes us say so
    // with "throws".
    public static void main(String[] args) throws IOException {
        List<String> lines = Files.readAllLines(Path.of(args[0]));
        String[] lengths = readColumn(lines, "length_mm");
        String[] widths = readColumn(lines, "width_mm");
        String[] varieties = readColumn(lines, "variety");
        String[] splits = readColumn(lines, "split");

        List<Seed> train = new ArrayList<>(), test = new ArrayList<>();
        for (int i = 0; i < lengths.length; i++) {
            var seed = new Seed(Double.parseDouble(lengths[i]),
                                Double.parseDouble(widths[i]), varieties[i]);
            (splits[i].equals("train") ? train : test).add(seed);
        }

        Locale root = Locale.ROOT;
        System.out.printf(root, "train_count %d%n", train.size());
        System.out.printf(root, "test_count %d%n", test.size());
        int bestK = 0;
        double bestAccuracy = -1.0;
        for (int k = 1; k <= 15; k += 2) {  // odd k only, so two varieties can't tie
            double accuracy = cvAccuracy(train, k);
            System.out.printf(root, "cv_accuracy_k%d %.6f%n", k, accuracy);
            if (accuracy > bestAccuracy) {  // strictly better, so ties keep the smaller k
                bestK = k;
                bestAccuracy = accuracy;
            }
        }

        // Only now touch the test seeds, once, with the chosen k and all of train.
        int correct = countCorrect(test, train, bestK);
        System.out.printf(root, "best_k %d%n", bestK);
        System.out.printf(root, "test_correct %d%n", correct);
        System.out.printf(root, "test_accuracy %.6f%n", (double) correct / test.size());
    }
}
