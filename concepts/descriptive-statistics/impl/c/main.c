/* Descriptive statistics on one CSV column, using only the C standard library.
 *
 * C has no statistics functions to avoid, and no growable arrays or CSV
 * reader either: the program grows its own array with realloc and finds the
 * column by splitting each line on commas. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define COLUMN "minutes"
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

/* qsort calls this to compare two elements, passed as untyped pointers. */
static int compare_doubles(const void *a, const void *b) {
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }

    size_t n;
    double *values = read_column(argv[1], COLUMN, &n);
    qsort(values, n, sizeof *values, compare_doubles);

    double total = 0;
    for (size_t i = 0; i < n; i++) total += values[i];
    double mean = total / n;

    /* Arrays count from 0: for n = 120 the middle pair is values[59], values[60]. */
    double median = n % 2 == 1 ? values[n / 2] : (values[n / 2 - 1] + values[n / 2]) / 2;

    /* Sample variance divides by n - 1, not n (Bessel's correction). */
    double squares = 0;
    for (size_t i = 0; i < n; i++) squares += (values[i] - mean) * (values[i] - mean);
    double variance = squares / (n - 1);

    printf("count %zu\n", n);
    printf("sum %.6f\n", total);
    printf("mean %.6f\n", mean);
    printf("median %.6f\n", median);
    printf("min %.6f\n", values[0]);
    printf("max %.6f\n", values[n - 1]);
    printf("range %.6f\n", values[n - 1] - values[0]);
    printf("variance %.6f\n", variance);
    printf("std_dev %.6f\n", sqrt(variance));

    free(values);
    return 0;
}
