/* Principal component analysis by power iteration, using only the C
 * standard library.
 *
 * Standardizes the four scores, builds their correlation matrix, and finds
 * the top two eigenvectors (the principal components): power iteration finds
 * the first, then deflation removes it from the matrix so the same steps
 * find the second. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE 1024
#define MAX_FIELDS 16
#define K 4 /* subjects */
#define STEPS 1000

static const char *SUBJECTS[K] = {"math", "physics", "reading", "writing"};

/* Cut a line at its commas into fields[], returning how many there are.
 * strtok writes '\0' over each comma, so the fields point into line. */
static int split(char *line, char *fields[]) {
    int count = 0;
    for (char *f = strtok(line, ",\r\n"); f && count < MAX_FIELDS; f = strtok(NULL, ",\r\n"))
        fields[count++] = f;
    return count;
}

/* Read the four subject columns, found by name, into rows of K scores.
 * double (*)[K] is a pointer to rows of K doubles, so scores[i][j] works
 * on one block of memory that realloc can grow. */
static double (*read_scores(const char *path, size_t *count))[K] {
    FILE *file = fopen(path, "r");
    if (!file) { perror(path); exit(1); }

    char line[MAX_LINE];
    char *fields[MAX_FIELDS];
    if (!fgets(line, sizeof line, file)) { fprintf(stderr, "empty file\n"); exit(1); }
    int fields_in_header = split(line, fields), cols[K];
    for (int j = 0; j < K; j++) {
        cols[j] = -1;
        for (int i = 0; i < fields_in_header; i++)
            if (strcmp(fields[i], SUBJECTS[j]) == 0) cols[j] = i;
        if (cols[j] < 0) { fprintf(stderr, "no column %s\n", SUBJECTS[j]); exit(1); }
    }

    size_t n = 0, capacity = 64;
    double (*scores)[K] = malloc(capacity * sizeof *scores);
    while (fgets(line, sizeof line, file)) {
        if (split(line, fields) < fields_in_header) continue;
        if (n == capacity) {
            capacity *= 2;
            scores = realloc(scores, capacity * sizeof *scores);
        }
        for (int j = 0; j < K; j++) scores[n][j] = strtod(fields[cols[j]], NULL);
        n++;
    }
    fclose(file);
    *count = n;
    return scores;
}

/* out = m v. An array parameter like m[K][K] is really a pointer, so the
 * result goes into an array the caller provides. (m can't be marked const:
 * before C23, passing a plain matrix to a const one is an error.) */
static void mat_vec(double m[K][K], const double v[K], double out[K]) {
    for (int i = 0; i < K; i++) {
        out[i] = 0;
        for (int j = 0; j < K; j++) out[i] += m[i][j] * v[j];
    }
}

static double dot(const double u[K], const double v[K]) {
    double total = 0;
    for (int i = 0; i < K; i++) total += u[i] * v[i];
    return total;
}

/* Power iteration: multiply by the matrix and rescale, STEPS times. Fills
 * v with the eigenvector and returns its eigenvalue. */
static double top_eigenvector(double m[K][K], double v[K]) {
    double mv[K];
    for (int i = 0; i < K; i++) v[i] = i == 0 ? 1 : 0;
    for (int step = 0; step < STEPS; step++) {
        mat_vec(m, v, mv);
        double length = sqrt(dot(mv, mv));
        for (int i = 0; i < K; i++) v[i] = mv[i] / length;
    }
    /* An eigenvector can point either way; make its first entry positive. */
    if (v[0] < 0)
        for (int i = 0; i < K; i++) v[i] = -v[i];
    mat_vec(m, v, mv);
    return dot(v, mv); /* the Rayleigh quotient v . (m v) */
}

static void report(int c, double value, const double pc[K]) {
    printf("eigenvalue_%d %.6f\n", c, value);
    /* Standardized columns each have variance 1, so the total is K. */
    printf("explained_%d %.6f\n", c, value / K);
    for (int j = 0; j < K; j++) printf("pc%d_%s %.6f\n", c, SUBJECTS[j], pc[j]);
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }

    size_t n;
    double (*z)[K] = read_scores(argv[1], &n);

    /* Standardize each column to mean 0 and (sample) standard deviation 1. */
    for (int j = 0; j < K; j++) {
        double total = 0, squares = 0;
        for (size_t i = 0; i < n; i++) total += z[i][j];
        double mean = total / n;
        for (size_t i = 0; i < n; i++) squares += (z[i][j] - mean) * (z[i][j] - mean);
        double sd = sqrt(squares / (n - 1));
        for (size_t i = 0; i < n; i++) z[i][j] = (z[i][j] - mean) / sd;
    }

    /* The correlation matrix: the covariance of the standardized columns. */
    double corr[K][K];
    for (int a = 0; a < K; a++)
        for (int b = 0; b < K; b++) {
            double total = 0;
            for (size_t i = 0; i < n; i++) total += z[i][a] * z[i][b];
            corr[a][b] = total / (n - 1);
        }

    double pc_1[K], pc_2[K], deflated[K][K];
    double value_1 = top_eigenvector(corr, pc_1);
    /* Deflation: subtract the first component's share, leaving the rest. */
    for (int a = 0; a < K; a++)
        for (int b = 0; b < K; b++) deflated[a][b] = corr[a][b] - value_1 * pc_1[a] * pc_1[b];
    double value_2 = top_eigenvector(deflated, pc_2);

    printf("count %zu\n", n);
    report(1, value_1, pc_1);
    report(2, value_2, pc_2);
    /* Arrays count from 0, so the first student is z[0]. */
    printf("student_1_pc1 %.6f\n", dot(z[0], pc_1));
    printf("student_1_pc2 %.6f\n", dot(z[0], pc_2));

    free(z);
    return 0;
}
