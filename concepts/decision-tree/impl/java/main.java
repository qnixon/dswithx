// A decision tree classifier (CART with Gini impurity), using only the Java
// standard library.
//
// Grows a tree on the training days by always making the split that leaves
// the two sides purest, then predicts rain for the test days. Prints the tree
// in preorder: each node is either a split (feature and threshold) or a leaf
// (its prediction).

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.TreeSet;

class Main {
    static final String[] FEATURES = {"humidity", "pressure", "wind"};
    static final int MAX_DEPTH = 3;
    static final int MIN_SIZE = 5;

    // A record is a small immutable class: Java writes the constructor, the
    // accessors (day.rain()), equals, and toString for us.
    record Day(double[] x, boolean rain) {}

    // "sealed ... permits" says a Node is a Leaf or a Split and nothing else,
    // so a switch over a Node that covers both needs no default case.
    sealed interface Node permits Leaf, Split {}
    record Leaf(boolean rain) implements Node {}
    record Split(int feature, double threshold, Node left, Node right) implements Node {}

    // A candidate split and its weighted impurity, before any children exist.
    record Candidate(double score, int feature, double threshold) {}

    // The named column of a CSV file, as strings. Reading a file can fail
    // with an IOException, and Java makes us say so with "throws".
    static String[] readColumn(Path path, String name) throws IOException {
        List<String> lines = Files.readAllLines(path);
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

    static int countYes(List<Day> days) {
        int yes = 0;
        for (Day day : days) {
            if (day.rain()) {
                yes++;
            }
        }
        return yes;
    }

    // Chance that two days drawn at random (with replacement) disagree.
    static double gini(List<Day> days) {
        double p = (double) countYes(days) / days.size();
        return 1 - p * p - (1 - p) * (1 - p);
    }

    // Rain only on a strict majority; an even split predicts no rain.
    static boolean majority(List<Day> days) {
        return 2 * countYes(days) > days.size();
    }

    // The days at or below the threshold (left) or above it (right).
    static List<Day> side(List<Day> days, int feature, double threshold, boolean left) {
        List<Day> out = new ArrayList<>();
        for (Day day : days) {
            if ((day.x()[feature] <= threshold) == left) {
                out.add(day);
            }
        }
        return out;
    }

    // The candidate with the lowest weighted Gini impurity, or null if no
    // feature has two distinct values. Features are tried in column order and
    // thresholds from smallest to largest; only a strictly lower score
    // replaces the best so far.
    static Candidate bestSplit(List<Day> days) {
        Candidate best = null;
        for (int f = 0; f < FEATURES.length; f++) {
            // A TreeSet keeps its values sorted and drops repeats.
            TreeSet<Double> values = new TreeSet<>();
            for (Day day : days) {
                values.add(day.x()[f]);
            }
            Double previous = null;
            for (double value : values) {
                if (previous != null) {
                    double threshold = (previous + value) / 2;
                    List<Day> left = side(days, f, threshold, true);
                    List<Day> right = side(days, f, threshold, false);
                    double score = (left.size() * gini(left) + right.size() * gini(right))
                        / days.size();
                    if (best == null || score < best.score()) {
                        best = new Candidate(score, f, threshold);
                    }
                }
                previous = value;
            }
        }
        return best;
    }

    static Node grow(List<Day> days, int depth) {
        double impurity = gini(days);
        if (impurity == 0 || days.size() < MIN_SIZE || depth == MAX_DEPTH) {
            return new Leaf(majority(days));
        }
        Candidate best = bestSplit(days);
        if (best == null || best.score() >= impurity) {
            return new Leaf(majority(days)); // no split makes the sides purer
        }
        int f = best.feature();
        double t = best.threshold();
        return new Split(f, t,
            grow(side(days, f, t, true), depth + 1),
            grow(side(days, f, t, false), depth + 1));
    }

    // A switch with record patterns matches the kind of node and pulls out
    // its fields in one step. Leaving out a case is a compile error.
    static boolean predict(Node node, double[] x) {
        return switch (node) {
            case Leaf(boolean rain) -> rain;
            case Split(int f, double t, Node left, Node right) ->
                predict(x[f] <= t ? left : right, x);
        };
    }

    // Every node, parents before children, left subtree before right.
    static void preorder(Node node, List<Node> out) {
        out.add(node);
        if (node instanceof Split split) {
            preorder(split.left(), out);
            preorder(split.right(), out);
        }
    }

    static int correct(Node tree, List<Day> days) {
        int right = 0;
        for (Day day : days) {
            if (predict(tree, day.x()) == day.rain()) {
                right++;
            }
        }
        return right;
    }

    public static void main(String[] args) throws IOException {
        Path path = Path.of(args[0]);
        String[][] columns = new String[FEATURES.length][];
        for (int f = 0; f < FEATURES.length; f++) {
            columns[f] = readColumn(path, FEATURES[f]);
        }
        String[] rain = readColumn(path, "rain");
        String[] split = readColumn(path, "split");

        // Strings are compared with equals, not ==, which compares objects.
        List<Day> train = new ArrayList<>();
        List<Day> test = new ArrayList<>();
        for (int row = 0; row < rain.length; row++) {
            double[] x = new double[FEATURES.length];
            for (int f = 0; f < FEATURES.length; f++) {
                x[f] = Double.parseDouble(columns[f][row]);
            }
            Day day = new Day(x, rain[row].equals("yes"));
            (split[row].equals("train") ? train : test).add(day);
        }
        Node tree = grow(train, 0);

        Locale root = Locale.ROOT;
        System.out.printf(root, "train_count %d%n", train.size());
        System.out.printf(root, "test_count %d%n", test.size());
        List<Node> nodes = new ArrayList<>();
        preorder(tree, nodes);
        int leaves = 0;
        for (int i = 0; i < nodes.size(); i++) {
            int k = i + 1;
            switch (nodes.get(i)) {
                case Leaf leaf -> {
                    System.out.printf(root, "node_%d_predict %s%n", k, leaf.rain() ? "yes" : "no");
                    leaves++;
                }
                case Split s -> {
                    System.out.printf(root, "node_%d_feature %s%n", k, FEATURES[s.feature()]);
                    System.out.printf(root, "node_%d_threshold %.6f%n", k, s.threshold());
                }
            }
        }
        System.out.printf(root, "leaves %d%n", leaves);

        int testCorrect = correct(tree, test);
        System.out.printf(root, "train_accuracy %.6f%n", (double) correct(tree, train) / train.size());
        System.out.printf(root, "correct %d%n", testCorrect);
        System.out.printf(root, "accuracy %.6f%n", (double) testCorrect / test.size());
    }
}
