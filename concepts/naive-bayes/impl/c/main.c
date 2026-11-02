/* Categorical naive Bayes with add-one (Laplace) smoothing, using only the C
 * standard library.
 *
 * Learns P(label) and P(feature value | label) by counting training rows, then
 * labels each test row with the label that has the highest log-probability. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define N_FEATURES 3
#define MAX_LINE 1024
#define MAX_TEXT 32
#define MAX_LABELS 16

static const char *FEATURES[N_FEATURES] = {"has_link", "mentions_money", "known_sender"};

/* One email. C strings are fixed-size character arrays here, copied in. */
typedef struct {
    char values[N_FEATURES][MAX_TEXT];
    char label[MAX_TEXT];
    char split[MAX_TEXT];
} Row;

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

/* Copy text into a fixed-size field, cutting it short rather than overflowing. */
static void copy_text(char dest[MAX_TEXT], const char *text) {
    snprintf(dest, MAX_TEXT, "%s", text);
}

/* Read every row. The array doubles in size whenever it fills, and the count
 * comes back through *count. */
static Row *read_rows(const char *path, size_t *count) {
    FILE *file = fopen(path, "r");
    if (!file) { perror(path); exit(1); }

    char line[MAX_LINE];
    if (!fgets(line, sizeof line, file)) { fprintf(stderr, "empty file\n"); exit(1); }
    int feature_col[N_FEATURES];
    for (int f = 0; f < N_FEATURES; f++) feature_col[f] = column_index(line, FEATURES[f]);
    int label_col = column_index(line, "label"), split_col = column_index(line, "split");
    for (int f = 0; f < N_FEATURES; f++)
        if (feature_col[f] < 0) { fprintf(stderr, "no column %s\n", FEATURES[f]); exit(1); }
    if (label_col < 0 || split_col < 0) { fprintf(stderr, "no label or split\n"); exit(1); }

    size_t n = 0, capacity = 64;
    Row *rows = malloc(capacity * sizeof *rows);
    while (fgets(line, sizeof line, file)) {
        Row row = {0};
        int index = 0;
        for (char *field = strtok(line, ",\r\n"); field; field = strtok(NULL, ",\r\n")) {
            for (int f = 0; f < N_FEATURES; f++)
                if (index == feature_col[f]) copy_text(row.values[f], field);
            if (index == label_col) copy_text(row.label, field);
            if (index == split_col) copy_text(row.split, field);
            index++;
        }
        if (index == 0) continue;   /* a blank line */
        if (n == capacity) {
            capacity *= 2;
            rows = realloc(rows, capacity * sizeof *rows);
        }
        rows[n++] = row;
    }
    fclose(file);
    *count = n;
    return rows;
}

/* Training rows and the model's counts. The labels are kept sorted. */
static const Row **train;
static size_t n_train;
static const char *labels[MAX_LABELS];
static int n_labels;
static int distinct_values[N_FEATURES];

/* Training rows with this label and, if feature >= 0, this value of it. */
static int count_rows(const char *label, int feature, const char *value) {
    int count = 0;
    for (size_t i = 0; i < n_train; i++)
        if (strcmp(train[i]->label, label) == 0 &&
            (feature < 0 || strcmp(train[i]->values[feature], value) == 0))
            count++;
    return count;
}

/* qsort calls this with pointers to two array elements, each a char pointer. */
static int compare_strings(const void *a, const void *b) {
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static double log_score(const Row *row, const char *label) {
    int label_count = count_rows(label, -1, NULL);
    /* Logs turn the product of probabilities into a sum, avoiding underflow. */
    double score = log((double)label_count / n_train);
    for (int f = 0; f < N_FEATURES; f++) {
        /* Add-one smoothing: an unseen value never gets probability zero. */
        int count = count_rows(label, f, row->values[f]) + 1;
        score += log((double)count / (label_count + distinct_values[f]));
    }
    return score;
}

/* Labels are tried in alphabetical order, and only a strictly higher score
 * replaces the best, so an exact tie goes to the first. */
static const char *classify(const Row *row) {
    const char *best = labels[0];
    double best_score = log_score(row, best);
    for (int l = 1; l < n_labels; l++) {
        double score = log_score(row, labels[l]);
        if (score > best_score) { best = labels[l]; best_score = score; }
    }
    return best;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }

    size_t n;
    Row *rows = read_rows(argv[1], &n);

    /* train points into rows, so the training set copies no data. */
    train = malloc(n * sizeof *train);
    for (size_t i = 0; i < n; i++)
        if (strcmp(rows[i].split, "train") == 0) train[n_train++] = &rows[i];
    if (n_train == 0) { fprintf(stderr, "no training rows\n"); return 1; }

    /* A label or value is new if no earlier training row has it. */
    for (size_t i = 0; i < n_train; i++) {
        int seen = 0;
        for (size_t e = 0; e < i && !seen; e++) seen = strcmp(train[e]->label, train[i]->label) == 0;
        if (!seen && n_labels < MAX_LABELS) labels[n_labels++] = train[i]->label;
        for (int f = 0; f < N_FEATURES; f++) {
            seen = 0;
            for (size_t e = 0; e < i && !seen; e++)
                seen = strcmp(train[e]->values[f], train[i]->values[f]) == 0;
            if (!seen) distinct_values[f]++;
        }
    }
    qsort(labels, n_labels, sizeof *labels, compare_strings);

    int test_count = 0, correct = 0;
    for (size_t i = 0; i < n; i++) {
        if (strcmp(rows[i].split, "test") != 0) continue;
        test_count++;
        if (strcmp(classify(&rows[i]), rows[i].label) == 0) correct++;
    }

    printf("train_count %zu\n", n_train);
    printf("test_count %d\n", test_count);
    printf("correct %d\n", correct);
    printf("accuracy %.6f\n", (double)correct / test_count);

    free(train);
    free(rows);
    return 0;
}
