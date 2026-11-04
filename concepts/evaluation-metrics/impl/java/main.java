// Evaluation metrics for a binary classifier, using only the Java standard
// library.
//
// Reads each part's true label and the model's score, then reports the
// confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
// the accuracy of never flagging anything, and the area under the ROC curve.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

class Main {
    // A record is a small immutable class; Java writes its constructor and
    // accessors, such as part.score(), for us.
    record Part(boolean defective, double score) {}

    static final Locale ROOT = Locale.ROOT;  // print 0.5, never 0,5

    // Sort every part into one of four counts at this threshold, then print
    // the counts and the ratios built from them.
    static void report(List<Part> parts, String suffix, double threshold) {
        int tp = 0, fp = 0, fn = 0, tn = 0;
        for (Part part : parts) {
            boolean flagged = part.score() >= threshold;  // flagged when the score reaches it
            if (flagged && part.defective()) {
                tp++;
            } else if (flagged) {
                fp++;
            } else if (part.defective()) {
                fn++;
            } else {
                tn++;
            }
        }
        // Casting to double first makes the division a real one; int / int
        // would throw away the fraction.
        double accuracy = (double) (tp + tn) / parts.size();
        double precision = (double) tp / (tp + fp);  // of the flagged, how many defective
        double recall = (double) tp / (tp + fn);     // of the defective, how many flagged
        double f1 = 2 * precision * recall / (precision + recall);

        System.out.printf(ROOT, "tp_at_%s %d%n", suffix, tp);
        System.out.printf(ROOT, "fp_at_%s %d%n", suffix, fp);
        System.out.printf(ROOT, "fn_at_%s %d%n", suffix, fn);
        System.out.printf(ROOT, "tn_at_%s %d%n", suffix, tn);
        System.out.printf(ROOT, "accuracy_at_%s %.6f%n", suffix, accuracy);
        System.out.printf(ROOT, "precision_at_%s %.6f%n", suffix, precision);
        System.out.printf(ROOT, "recall_at_%s %.6f%n", suffix, recall);
        System.out.printf(ROOT, "f1_at_%s %.6f%n", suffix, f1);
    }

    // The chance that a random defective part outscores a random good one.
    // Compare every pair, scoring 2 for a win and 1 for a tie, so the count
    // stays a whole number until the final division.
    static double auc(List<Part> parts) {
        List<Double> defective = new ArrayList<>(), good = new ArrayList<>();
        for (Part part : parts) {
            (part.defective() ? defective : good).add(part.score());
        }
        long points = 0;
        // Unboxing to the primitive double matters: == on two Double objects
        // would compare references, not values.
        for (double d : defective) {
            for (double g : good) {
                if (d > g) {
                    points += 2;
                } else if (d == g) {
                    points += 1;
                }
            }
        }
        return (double) points / (2.0 * defective.size() * good.size());
    }

    // Reading a file can fail with an IOException, and Java makes us say so
    // with "throws".
    public static void main(String[] args) throws IOException {
        List<String> lines = Files.readAllLines(Path.of(args[0]));
        List<Part> parts = new ArrayList<>();
        int defective = 0;
        for (String line : lines.subList(1, lines.size())) {  // skip the header
            if (line.isBlank()) {
                continue;
            }
            String[] fields = line.split(",");
            // Strings are compared with equals; == would compare objects.
            Part part = new Part(fields[0].equals("1"), Double.parseDouble(fields[1]));
            parts.add(part);
            if (part.defective()) {
                defective++;
            }
        }

        System.out.printf(ROOT, "parts %d%n", parts.size());
        System.out.printf(ROOT, "defective %d%n", defective);
        // Never flagging anything is right about every good part.
        System.out.printf(ROOT, "baseline_accuracy %.6f%n",
                (double) (parts.size() - defective) / parts.size());
        report(parts, "50", 0.5);
        report(parts, "30", 0.3);
        System.out.printf(ROOT, "auc %.6f%n", auc(parts));
    }
}
