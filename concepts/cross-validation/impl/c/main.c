/* 5-fold cross-validation for k-nearest neighbors, using only the C
 * standard library.
 *
 * Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
 * holding out one fold at a time, picks the k with the best average
 * accuracy, and then scores that k once on the untouched test seeds. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FOLDS 5
#define MAX_K 15
#define MAX_LINE 1024
#define MAX_FIELDS 16
#define MAX_LABEL 16

/* A struct groups one seed's measurements with its variety. */
struct seed {
    double length, width;
    char variety[MAX_LABEL];
};

/* A growable array of seeds: realloc doubles its room whenever it fills. */
struct seeds {
    struct seed *items;
    size_t count, capacity;
};

static void push(struct seeds *list, struct seed s) {
    if (list->count == list->capacity) {
        list->capacity = list->capacity ? list->capacity * 2 : 64;
        list->items = realloc(list->items, list->capacity * sizeof *list->items);
    }
    list->items[list->count++] = s;
}

/* Cut a line at its commas, in place, and return the number of fields.
 * strtok replaces each comma with '\0', so fields[i] points into line. */
static int split(char *line, char *fields[]) {
    int n = 0;
    for (char *f = strtok(line, ",\r\n"); f && n < MAX_FIELDS; f = strtok(NULL, ",\r\n"))
        fields[n++] = f;
    return n;
}

/* Return the 0-based position of name among the header fields, or exit. */
static int column(char *header[], int n, const char *name) {
    for (int i = 0; i < n; i++)
        if (strcmp(header[i], name) == 0) return i;
    fprintf(stderr, "no column %s\n", name);
    exit(1);
}

static void read_seeds(const char *path, struct seeds *train, struct seeds *test) {
    FILE *file = fopen(path, "r");
    if (!file) { perror(path); exit(1); }

    char line[MAX_LINE], *fields[MAX_FIELDS];
    if (!fgets(line, sizeof line, file)) { fprintf(stderr, "empty file\n"); exit(1); }
    int n = split(line, fields);
    int length = column(fields, n, "length_mm"), width = column(fields, n, "width_mm");
    int variety = column(fields, n, "variety"), which = column(fields, n, "split");

    while (fgets(line, sizeof line, file)) {
        if (split(line, fields) != n) continue;
        struct seed s = { strtod(fields[length], NULL), strtod(fields[width], NULL), "" };
        /* snprintf copies the label and always ends it with '\0'. */
        snprintf(s.variety, sizeof s.variety, "%s", fields[variety]);
        push(strcmp(fields[which], "train") == 0 ? train : test, s);
    }
    fclose(file);
}

/* A training seed's distance from the test seed, and its row in the set. */
struct neighbor {
    double distance;
    size_t index;
};

/* qsort isn't stable, so equal distances fall back to row order. */
static int compare_neighbors(const void *a, const void *b) {
    const struct neighbor *x = a, *y = b;
    if (x->distance != y->distance) return (x->distance > y->distance) - (x->distance < y->distance);
    return (x->index > y->index) - (x->index < y->index);
}

static const char *classify(const struct seed *point, const struct seeds *train, int k,
                            struct neighbor *scratch) {
    for (size_t i = 0; i < train->count; i++) {
        double dl = point->length - train->items[i].length;
        double dw = point->width - train->items[i].width;
        scratch[i] = (struct neighbor){ sqrt(dl * dl + dw * dw), i };
    }
    qsort(scratch, train->count, sizeof *scratch, compare_neighbors);

    /* Count each of the k nearest labels' votes among the k; the first
     * label to reach the highest count wins. */
    const char *best = NULL;
    int best_votes = 0;
    for (int i = 0; i < k; i++) {
        const char *label = train->items[scratch[i].index].variety;
        int votes = 0;
        for (int j = 0; j < k; j++)
            if (strcmp(train->items[scratch[j].index].variety, label) == 0) votes++;
        if (votes > best_votes) { best = label; best_votes = votes; }
    }
    return best;
}

static int count_correct(const struct seed *points, size_t n, const struct seeds *train,
                         int k, struct neighbor *scratch) {
    int correct = 0;
    for (size_t i = 0; i < n; i++)
        if (strcmp(classify(&points[i], train, k, scratch), points[i].variety) == 0)
            correct++;
    return correct;
}

/* Fold f is rows f*size up to (f+1)*size. The rows are already shuffled, so
 * consecutive blocks make fair folds. The held-out fold is just a pointer
 * into train; the other rows are copied, in order, into the rest buffer. */
static double cv_accuracy(const struct seeds *train, int k, struct seeds *rest,
                          struct neighbor *scratch) {
    size_t size = train->count / FOLDS;
    int correct = 0;
    for (size_t f = 0; f < FOLDS; f++) {
        size_t start = f * size, end = start + size;
        rest->count = 0;
        for (size_t i = 0; i < train->count; i++)
            if (i < start || i >= end) push(rest, train->items[i]);
        correct += count_correct(&train->items[start], size, rest, k, scratch);
    }
    return (double)correct / train->count;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }

    struct seeds train = {0}, test = {0}, rest = {0};
    read_seeds(argv[1], &train, &test);
    if (train.count < FOLDS * MAX_K || test.count == 0) { fprintf(stderr, "too few seeds\n"); return 1; }

    struct neighbor *scratch = malloc(train.count * sizeof *scratch);
    printf("train_count %zu\n", train.count);
    printf("test_count %zu\n", test.count);

    int best_k = 0;
    double best_accuracy = -1.0;
    for (int k = 1; k <= MAX_K; k += 2) {  /* odd k only */
        double accuracy = cv_accuracy(&train, k, &rest, scratch);
        printf("cv_accuracy_k%d %.6f\n", k, accuracy);
        if (accuracy > best_accuracy) {  /* strictly better, so ties keep the smaller k */
            best_k = k;
            best_accuracy = accuracy;
        }
    }

    /* Only now touch the test seeds, once, with the chosen k and all of train. */
    int correct = count_correct(test.items, test.count, &train, best_k, scratch);
    printf("best_k %d\n", best_k);
    printf("test_correct %d\n", correct);
    printf("test_accuracy %.6f\n", (double)correct / test.count);

    free(scratch);
    free(train.items);
    free(test.items);
    free(rest.items);
    return 0;
}
