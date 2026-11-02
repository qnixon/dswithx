// Principal component analysis by power iteration, using only the Java
// standard library.
//
// Standardizes the four scores, builds their correlation matrix, and finds the
// top two eigenvectors (the principal components): power iteration finds the
// first, then deflation removes it from the matrix so the same steps find the
// second. The JDK has no matrix type or eigenvalue routine, so a matrix is a
// double[][] and the products are small helper methods.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

class Main {
    static final String[] SUBJECTS = {"math", "physics", "reading", "writing"};
    static final int STEPS = 1000;

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

    static double dot(double[] u, double[] v) {
        double total = 0;
        for (int i = 0; i < u.length; i++) {
            total += u[i] * v[i];
        }
        return total;
    }

    // A double[][] is an array of row arrays, so m[i] is row i, ready for dot.
    static double[] matVec(double[][] m, double[] v) {
        double[] out = new double[m.length];
        for (int i = 0; i < m.length; i++) {
            out[i] = dot(m[i], v);
        }
        return out;
    }

    static double[] normalize(double[] v) {
        double length = Math.sqrt(dot(v, v));
        double[] out = new double[v.length];
        for (int i = 0; i < v.length; i++) {
            out[i] = v[i] / length;
        }
        return out;
    }

    // Power iteration: multiply by the matrix and rescale, STEPS times. The
    // eigenvalue is v . (M v), which the caller computes from the vector.
    static double[] topEigenvector(double[][] m) {
        double[] v = new double[m.length]; // Java fills new arrays with zeros
        v[0] = 1;
        for (int step = 0; step < STEPS; step++) {
            v = normalize(matVec(m, v));
        }
        // An eigenvector can point either way; make its first entry positive.
        if (v[0] < 0) {
            for (int i = 0; i < v.length; i++) {
                v[i] = -v[i];
            }
        }
        return v;
    }

    public static void main(String[] args) throws IOException {
        int k = SUBJECTS.length;
        // columns[j] holds every student's score in subject j.
        double[][] columns = new double[k][];
        for (int j = 0; j < k; j++) {
            columns[j] = readColumn(Path.of(args[0]), SUBJECTS[j]);
        }
        int n = columns[0].length;

        // Standardize each column to mean 0 and (sample) standard deviation
        // 1. z[r][j] is student r's standardized score in subject j.
        double[][] z = new double[n][k];
        for (int j = 0; j < k; j++) {
            double sum = 0;
            for (double x : columns[j]) sum += x;
            double mean = sum / n;
            double squares = 0;
            for (double x : columns[j]) squares += (x - mean) * (x - mean);
            double sd = Math.sqrt(squares / (n - 1));
            for (int r = 0; r < n; r++) {
                z[r][j] = (columns[j][r] - mean) / sd;
            }
        }

        // The correlation matrix: the covariance of the standardized columns.
        double[][] corr = new double[k][k];
        for (double[] row : z) {
            for (int i = 0; i < k; i++) {
                for (int j = 0; j < k; j++) {
                    corr[i][j] += row[i] * row[j] / (n - 1);
                }
            }
        }

        double[] pc1 = topEigenvector(corr);
        double value1 = dot(pc1, matVec(corr, pc1));
        // Deflation: subtract the first component's share, leaving the rest.
        // We build a new matrix; "deflated = corr" would only copy the
        // reference, and the loop below would change corr too.
        double[][] deflated = new double[k][k];
        for (int i = 0; i < k; i++) {
            for (int j = 0; j < k; j++) {
                deflated[i][j] = corr[i][j] - value1 * pc1[i] * pc1[j];
            }
        }
        double[] pc2 = topEigenvector(deflated);
        double value2 = dot(pc2, matVec(deflated, pc2));

        // printf follows the computer's language settings unless told
        // otherwise; Locale.ROOT keeps the decimal point a point.
        Locale root = Locale.ROOT;
        System.out.printf(root, "count %d%n", n);
        double[] values = {value1, value2};
        double[][] pcs = {pc1, pc2};
        for (int c = 0; c < 2; c++) {
            System.out.printf(root, "eigenvalue_%d %.6f%n", c + 1, values[c]);
            // Standardized columns each have variance 1, so the total is k.
            System.out.printf(root, "explained_%d %.6f%n", c + 1, values[c] / k);
            for (int j = 0; j < k; j++) {
                System.out.printf(root, "pc%d_%s %.6f%n", c + 1, SUBJECTS[j], pcs[c][j]);
            }
        }
        System.out.printf(root, "student_1_pc1 %.6f%n", dot(z[0], pc1));
        System.out.printf(root, "student_1_pc2 %.6f%n", dot(z[0], pc2));
    }
}
