// Categorical naive Bayes with add-one (Laplace) smoothing, using only the
// Java standard library.
//
// Learns P(label) and P(feature value | label) by counting training rows,
// then labels each test row with the label that has the highest
// log-probability.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

class Main {
    static final String[] FEATURES = {"has_link", "mentions_money", "known_sender"};

    // One count: how many training rows of a label have a feature value. A
    // record gets equals and hashCode from its fields, so two Keys with the
    // same three strings find the same map entry.
    record Key(String feature, String value, String label) {}

    // The named column of the CSV lines, as an array of strings.
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

    public static void main(String[] args) throws IOException {
        // Reading a file can fail with an IOException, and Java makes us say
        // so with "throws".
        List<String> lines = Files.readAllLines(Path.of(args[0]));
        String[] labels = readColumn(lines, "label");
        String[] split = readColumn(lines, "split");
        // features[f][row] is feature f's value in that row.
        String[][] features = new String[FEATURES.length][];
        for (int f = 0; f < FEATURES.length; f++) {
            features[f] = readColumn(lines, FEATURES[f]);
        }

        // A TreeMap keeps its keys sorted, so the labels come out in
        // alphabetical order. merge(key, 1, Integer::sum) adds one, starting
        // from 1 when the key is new.
        Map<String, Integer> labelCounts = new TreeMap<>();
        Map<Key, Integer> valueCounts = new HashMap<>();
        List<Set<String>> seen = new ArrayList<>(); // distinct values
        for (int f = 0; f < FEATURES.length; f++) {
            seen.add(new HashSet<>());
        }
        int trainCount = 0;
        for (int row = 0; row < labels.length; row++) {
            if (!split[row].equals("train")) {
                continue;
            }
            trainCount++;
            labelCounts.merge(labels[row], 1, Integer::sum);
            for (int f = 0; f < FEATURES.length; f++) {
                valueCounts.merge(new Key(FEATURES[f], features[f][row], labels[row]), 1, Integer::sum);
                seen.get(f).add(features[f][row]);
            }
        }

        int testCount = 0;
        int correct = 0;
        for (int row = 0; row < labels.length; row++) {
            if (!split[row].equals("test")) {
                continue;
            }
            testCount++;
            // Labels are tried in alphabetical order and only a strictly
            // higher score replaces the best, so an exact tie goes to the
            // first.
            String best = null;
            double bestScore = Double.NEGATIVE_INFINITY;
            for (var entry : labelCounts.entrySet()) {
                String label = entry.getKey();
                int n = entry.getValue();
                // Logs turn the product of probabilities into a sum, avoiding
                // underflow. (double) keeps int / int from rounding down to 0.
                double score = Math.log((double) n / trainCount);
                for (int f = 0; f < FEATURES.length; f++) {
                    // Add-one smoothing: an unseen value never gets
                    // probability zero; getOrDefault reads it as 0.
                    int count = valueCounts.getOrDefault(new Key(FEATURES[f], features[f][row], label), 0) + 1;
                    score += Math.log((double) count / (n + seen.get(f).size()));
                }
                if (best == null || score > bestScore) {
                    best = label;
                    bestScore = score;
                }
            }
            // equals compares the text; == would compare the objects.
            if (best.equals(labels[row])) {
                correct++;
            }
        }

        Locale root = Locale.ROOT;
        System.out.printf(root, "train_count %d%n", trainCount);
        System.out.printf(root, "test_count %d%n", testCount);
        System.out.printf(root, "correct %d%n", correct);
        System.out.printf(root, "accuracy %.6f%n", (double) correct / testCount);
    }
}
