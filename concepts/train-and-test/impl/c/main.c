/* Train and test error for polynomials of degree 1 to 8, using only the C
 * standard library.
 *
 * Each polynomial is fitted by least squares to the training drives only:
 * we build the normal equations and solve them by Gaussian elimination.
 * Then we measure its root-mean-square error on the training drives and on
 * the test drives it never saw. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_DEGREE 8
#define MAX_TERMS (MAX_DEGREE + 1)
#define MAX_DRIVES 1000
#define MAX_LINE 256

/* Training and test drives in separate parallel arrays: speed and litres. */
static double train_x[MAX_DRIVES], train_y[MAX_DRIVES];
static double test_x[MAX_DRIVES], test_y[MAX_DRIVES];
static int train_count, test_count;

/* The training range, used to map every speed onto -1 to 1. */
static double mid, half;

static double scale(double x) { return (x - mid) / half; }

/* Cut a line at its commas, in place, and return the number of fields.
 * strtok replaces each comma with '\0', so fields[i] points into line. */
static int split(char *line, char *fields[], int max) {
    int n = 0;
    for (char *f = strtok(line, ",\r\n"); f && n < max; f = strtok(NULL, ",\r\n"))
        fields[n++] = f;
    return n;
}

/* Solve a x = b by Gaussian elimination with partial pivoting. The
 * augmented matrix m is n rows by n + 1 columns; the last column is b. */
static void solve(int n, double m[MAX_TERMS][MAX_TERMS + 1], double x[]) {
    for (int col = 0; col < n; col++) {
        /* Swap up the row with the largest entry in this column, which keeps
         * the rounding error small. C arrays can't be assigned whole, so the
         * swap goes entry by entry. */
        int pivot = col;
        for (int r = col + 1; r < n; r++)
            if (fabs(m[r][col]) > fabs(m[pivot][col])) pivot = r;
        for (int c = 0; c <= n; c++) {
            double t = m[col][c];
            m[col][c] = m[pivot][c];
            m[pivot][c] = t;
        }
        for (int r = col + 1; r < n; r++) {
            double factor = m[r][col] / m[col][col];
            for (int c = col; c <= n; c++) m[r][c] -= factor * m[col][c];
        }
    }
    /* Back substitution, from the last unknown up. */
    for (int r = n - 1; r >= 0; r--) {
        double s = m[r][n];
        for (int c = r + 1; c < n; c++) s -= m[r][c] * x[c];
        x[r] = s / m[r][r];
    }
}

/* Least squares: the coefficients solve (Z^T Z) c = Z^T y, where row i of
 * Z is 1, z_i, z_i^2, ..., z_i^degree. */
static void fit(int degree, double coefs[]) {
    int size = degree + 1;
    double m[MAX_TERMS][MAX_TERMS + 1] = {{0}};
    for (int k = 0; k < train_count; k++) {
        double z = scale(train_x[k]);
        for (int i = 0; i < size; i++) {
            m[i][size] += train_y[k] * pow(z, i);
            for (int j = 0; j < size; j++) m[i][j] += pow(z, i + j);
        }
    }
    solve(size, m, coefs);
}

static double rmse(const double coefs[], int degree, const double xs[],
                   const double ys[], int n) {
    double total = 0;
    for (int k = 0; k < n; k++) {
        double z = scale(xs[k]), predicted = 0;
        for (int i = 0; i <= degree; i++) predicted += coefs[i] * pow(z, i);
        total += (predicted - ys[k]) * (predicted - ys[k]);
    }
    return sqrt(total / n);
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }
    FILE *file = fopen(argv[1], "r");
    if (!file) { perror(argv[1]); return 1; }

    char line[MAX_LINE], *fields[3];
    if (!fgets(line, sizeof line, file)) { fprintf(stderr, "empty file\n"); return 1; }
    while (fgets(line, sizeof line, file)) {
        if (split(line, fields, 3) != 3) continue;
        double x = strtod(fields[0], NULL), y = strtod(fields[1], NULL);
        if (strcmp(fields[2], "train") == 0 && train_count < MAX_DRIVES) {
            train_x[train_count] = x;
            train_y[train_count++] = y;
        } else if (test_count < MAX_DRIVES) {
            test_x[test_count] = x;
            test_y[test_count++] = y;
        }
    }
    fclose(file);

    /* Map the training speeds onto -1 to 1. Raw speeds to the 16th power
     * (the largest entry at degree 8) would swamp the small ones. */
    double low = train_x[0], high = train_x[0];
    for (int k = 1; k < train_count; k++) {
        if (train_x[k] < low) low = train_x[k];
        if (train_x[k] > high) high = train_x[k];
    }
    mid = (low + high) / 2;
    half = (high - low) / 2;

    double train_error[MAX_DEGREE + 1], test_error[MAX_DEGREE + 1];
    for (int d = 1; d <= MAX_DEGREE; d++) {
        double coefs[MAX_TERMS];
        fit(d, coefs);
        train_error[d] = rmse(coefs, d, train_x, train_y, train_count);
        test_error[d] = rmse(coefs, d, test_x, test_y, test_count);
    }

    printf("train_count %d\n", train_count);
    printf("test_count %d\n", test_count);
    for (int d = 1; d <= MAX_DEGREE; d++) printf("train_rmse_d%d %.6f\n", d, train_error[d]);
    for (int d = 1; d <= MAX_DEGREE; d++) printf("test_rmse_d%d %.6f\n", d, test_error[d]);
    return 0;
}
