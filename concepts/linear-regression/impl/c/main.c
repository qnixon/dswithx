/* Simple linear regression by least squares, using only the C standard library.
 *
 * Fits score = intercept + slope * hours. C has no regression or correlation
 * function to avoid; the sums are plain loops over two arrays of doubles. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define X "hours"
#define Y "score"
#define MAX_LINE 1024

/* Return the 0-based position of name in a header line, or -1. strtok
 * replaces each comma with '\0' as it goes, so it works on a copy. */
static int column_index(const char *header, const char *name) {
    char copy[MAX_LINE];
    strcpy(copy, header);
    int index = 0;
    for (char *field = strtok(copy, ",\r\n"); field; field = strtok(NULL, ",\r\n")) {
        if (strcmp(field, name) == 0) return index;
        index++;
    }
    return -1;
}

/* Read one column as doubles. The array doubles in size whenever it fills,
 * and the count comes back through *count. */
static double *read_column(const char *path, const char *name, size_t *count) {
    FILE *file = fopen(path, "r");
    if (!file) { perror(path); exit(1); }

    char line[MAX_LINE];
    if (!fgets(line, sizeof line, file)) { fprintf(stderr, "empty file\n"); exit(1); }
    int index = column_index(line, name);
    if (index < 0) { fprintf(stderr, "no column %s\n", name); exit(1); }

    size_t n = 0, capacity = 64;
    double *values = malloc(capacity * sizeof *values);
    while (fgets(line, sizeof line, file)) {
        char *field = strtok(line, ",");
        for (int i = 0; i < index && field; i++) field = strtok(NULL, ",");
        if (!field) continue;
        if (n == capacity) {
            capacity *= 2;
            values = realloc(values, capacity * sizeof *values);
        }
        values[n++] = strtod(field, NULL);
    }
    fclose(file);
    *count = n;
    return values;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }

    /* Each column is read on its own; row i of the file is xs[i] and ys[i]. */
    size_t n, ny;
    double *xs = read_column(argv[1], X, &n);
    double *ys = read_column(argv[1], Y, &ny);
    if (n != ny) { fprintf(stderr, "columns differ in length\n"); return 1; }

    /* First pass: the means. */
    double sum_x = 0, sum_y = 0;
    for (size_t i = 0; i < n; i++) { sum_x += xs[i]; sum_y += ys[i]; }
    double mean_x = sum_x / n, mean_y = sum_y / n;

    /* Second pass: sums of squared deviations and of cross-products. */
    double sxx = 0, syy = 0, sxy = 0;
    for (size_t i = 0; i < n; i++) {
        double dx = xs[i] - mean_x, dy = ys[i] - mean_y;
        sxx += dx * dx;
        syy += dy * dy;
        sxy += dx * dy;
    }

    double slope = sxy / sxx;
    double intercept = mean_y - slope * mean_x;
    double r = sxy / sqrt(sxx * syy);

    printf("count %zu\n", n);
    printf("slope %.6f\n", slope);
    printf("intercept %.6f\n", intercept);
    printf("r %.6f\n", r);
    printf("r_squared %.6f\n", r * r);

    free(xs);
    free(ys);
    return 0;
}
