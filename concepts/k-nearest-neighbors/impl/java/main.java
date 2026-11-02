// k-nearest neighbors classification, using only the Java standard library.
//
// Each test seed is labelled with the majority variety among its K nearest
// training seeds, by Euclidean distance.

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
    static final int K = 5;

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

    static String classify(Seed point, List<Seed> train) {
        List<Neighbor> neighbors = new ArrayList<>();
        for (Seed seed : train) {
            // Math.hypot(dx, dy) is the straight-line distance, sqrt(dx*dx + dy*dy).
            double d = Math.hypot(point.length() - seed.length(), point.width() - seed.width());
            neighbors.add(new Neighbor(d, seed.variety()));
        }
        // List.sort is stable, so equal distances keep file order.
        neighbors.sort(Comparator.comparingDouble(Neighbor::distance));

        // Count the votes of the K nearest: groupingBy makes a map from each
        // variety to how many neighbors have it.
        Map<String, Long> votes = neighbors.subList(0, K).stream()
            .collect(Collectors.groupingBy(Neighbor::variety, Collectors.counting()));

        // With two varieties and an odd K, the vote can't tie.
        String winner = null;
        for (var vote : votes.entrySet()) {
            if (winner == null || vote.getValue() > votes.get(winner)) {
                winner = vote.getKey();
            }
        }
        return winner;
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
            // Strings are compared with equals; == would compare objects.
            (splits[i].equals("train") ? train : test).add(seed);
        }

        int correct = 0;
        for (Seed seed : test) {
            if (classify(seed, train).equals(seed.variety())) {
                correct++;
            }
        }

        Locale root = Locale.ROOT;
        System.out.printf(root, "train_count %d%n", train.size());
        System.out.printf(root, "test_count %d%n", test.size());
        System.out.printf(root, "correct %d%n", correct);
        System.out.printf(root, "accuracy %.6f%n", (double) correct / test.size());
    }
}
