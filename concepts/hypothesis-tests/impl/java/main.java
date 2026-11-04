// Exact two-sided permutation test for a difference in means, using only the
// Java standard library.
//
// If compost made no difference, the "compost" and "control" labels are
// arbitrary, and any 8 of the 16 plants could have carried the compost label.
// We try every one of those splits and count how many give a difference at
// least as large as the one we observed. That fraction is the p-value.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

class Main {
    // Reading a file can fail with an IOException, and Java makes us say so
    // with "throws".
    public static void main(String[] args) throws IOException {
        List<String> lines = Files.readAllLines(Path.of(args[0]));
        List<Integer> control = new ArrayList<>(), compost = new ArrayList<>();
        for (String line : lines.subList(1, lines.size())) {  // skip the header
            if (line.isBlank()) {
                continue;
            }
            String[] fields = line.split(",");
            // Strings are compared with equals; == would compare objects.
            (fields[0].equals("compost") ? compost : control).add(Integer.parseInt(fields[1]));
        }
        int n = compost.size();
        if (n == 0 || control.size() != n) {
            throw new IllegalArgumentException("need two groups of equal size");
        }

        List<Integer> plants = new ArrayList<>(control);
        plants.addAll(compost);
        long controlSum = 0, compostSum = 0;
        for (int grams : control) controlSum += grams;
        for (int grams : compost) compostSum += grams;
        long total = controlSum + compostSum;

        // Both groups have the same size, so comparing totals is the same as
        // comparing means, and totals stay whole numbers: no floating-point
        // near-ties.
        long observed = compostSum - controlSum;

        // Each whole number from 0 to 2^16 - 1 is a mask: bit i set means
        // plant i is labeled compost. Integer.bitCount counts the set bits,
        // so the masks with exactly n of them are the splits.
        int splits = 0, asExtreme = 0;
        for (int mask = 0; mask < 1 << plants.size(); mask++) {
            if (Integer.bitCount(mask) != n) {
                continue;
            }
            long chosen = 0;
            for (int i = 0; i < plants.size(); i++) {
                if ((mask & (1 << i)) != 0) {
                    chosen += plants.get(i);
                }
            }
            long difference = chosen - (total - chosen);
            splits++;
            if (Math.abs(difference) >= Math.abs(observed)) {  // two-sided
                asExtreme++;
            }
        }

        Locale root = Locale.ROOT;
        System.out.printf(root, "control_count %d%n", control.size());
        System.out.printf(root, "compost_count %d%n", n);
        System.out.printf(root, "control_mean %.6f%n", (double) controlSum / n);
        System.out.printf(root, "compost_mean %.6f%n", (double) compostSum / n);
        System.out.printf(root, "observed_difference %.6f%n", (double) observed / n);
        System.out.printf(root, "splits %d%n", splits);
        System.out.printf(root, "as_extreme %d%n", asExtreme);
        System.out.printf(root, "p_value %.6f%n", (double) asExtreme / splits);
    }
}
