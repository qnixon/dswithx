/* A decision tree classifier (CART with Gini impurity), using only the C
 * standard library.
 *
 * Grows a tree on the training days by always making the split that leaves
 * the two sides purest, then predicts rain for the test days. Prints the tree
 * in preorder: each node is either a split (feature and threshold) or a leaf
 * (its prediction). */

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define N_FEATURES 3
#define MAX_DEPTH 3
#define MIN_SIZE 5
#define MAX_LINE 1024
#define MAX_FIELDS 16

static const char *FEATURES[N_FEATURES] = {"humidity", "pressure", "wind"};

struct day {
    double x[N_FEATURES];
    bool rain;
};

/* One struct serves for both kinds of node. A split has two children; a leaf
 * has NULL children and a label. The struct can point to itself because a
 * pointer's size is known before the struct is complete. */
struct node {
    int feature;
    double threshold;
    struct node *left, *right;
    bool label;
};

static bool is_leaf(const struct node *n) { return n->left == NULL; }

/* Split a line at its commas into fields[], returning how many there are.
 * strtok replaces each comma with '\0', so the fields point into line. */
static int split_fields(char *line, char *fields[]) {
    int count = 0;
    for (char *f = strtok(line, ",\r\n"); f && count < MAX_FIELDS; f = strtok(NULL, ",\r\n"))
        fields[count++] = f;
    return count;
}

/* Return the 0-based position of name among the header fields, or exit. */
static int column(char *header[], int count, const char *name) {
    for (int i = 0; i < count; i++)
        if (strcmp(header[i], name) == 0) return i;
    fprintf(stderr, "no column %s\n", name);
    exit(1);
}

/* Append one day to a growable array, doubling its capacity when full. */
static void push(struct day **days, size_t *n, size_t *capacity, struct day d) {
    if (*n == *capacity) {
        *capacity = *capacity ? *capacity * 2 : 64;
        *days = realloc(*days, *capacity * sizeof **days);
    }
    (*days)[(*n)++] = d;
}

static void read_days(const char *path, struct day **train, size_t *n_train,
                      struct day **test, size_t *n_test) {
    FILE *file = fopen(path, "r");
    if (!file) { perror(path); exit(1); }

    char header_line[MAX_LINE], line[MAX_LINE];
    char *fields[MAX_FIELDS];
    if (!fgets(header_line, sizeof header_line, file)) { fprintf(stderr, "empty file\n"); exit(1); }
    int count = split_fields(header_line, fields);
    int feature_column[N_FEATURES];
    for (int f = 0; f < N_FEATURES; f++) feature_column[f] = column(fields, count, FEATURES[f]);
    int rain_column = column(fields, count, "rain");
    int split_column = column(fields, count, "split");

    size_t train_capacity = 0, test_capacity = 0;
    *train = *test = NULL;
    *n_train = *n_test = 0;
    while (fgets(line, sizeof line, file)) {
        if (split_fields(line, fields) < count) continue;
        struct day d;
        for (int f = 0; f < N_FEATURES; f++) d.x[f] = strtod(fields[feature_column[f]], NULL);
        d.rain = strcmp(fields[rain_column], "yes") == 0;
        if (strcmp(fields[split_column], "train") == 0)
            push(train, n_train, &train_capacity, d);
        else
            push(test, n_test, &test_capacity, d);
    }
    fclose(file);
}

static size_t count_yes(const struct day *days, size_t n) {
    size_t yes = 0;
    for (size_t i = 0; i < n; i++) yes += days[i].rain;
    return yes;
}

/* The chance that two days drawn at random (with replacement) disagree. */
static double gini(const struct day *days, size_t n) {
    double p = (double)count_yes(days, n) / n;
    return 1 - p * p - (1 - p) * (1 - p);
}

/* "yes" only for a strict majority; an even split predicts "no". */
static bool majority(const struct day *days, size_t n) {
    return 2 * count_yes(days, n) > n;
}

/* Copy the days at or below the threshold into left, the rest into right.
 * Both arrays are the caller's, each with room for n days. */
static void partition(const struct day *days, size_t n, int f, double threshold,
                      struct day *left, size_t *n_left, struct day *right, size_t *n_right) {
    *n_left = *n_right = 0;
    for (size_t i = 0; i < n; i++) {
        if (days[i].x[f] <= threshold) left[(*n_left)++] = days[i];
        else right[(*n_right)++] = days[i];
    }
}

/* qsort calls this to compare two elements, passed as untyped pointers. */
static int compare_doubles(const void *a, const void *b) {
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

/* Find the split with the lowest weighted Gini impurity. Features are tried
 * in column order and thresholds from smallest to largest; only a strictly
 * lower score replaces the best so far. Returns false if no feature has two
 * distinct values. */
static bool best_split(const struct day *days, size_t n,
                       double *score, int *feature, double *threshold) {
    bool found = false;
    double *values = malloc(n * sizeof *values);
    struct day *left = malloc(n * sizeof *left), *right = malloc(n * sizeof *right);
    for (int f = 0; f < N_FEATURES; f++) {
        for (size_t i = 0; i < n; i++) values[i] = days[i].x[f];
        qsort(values, n, sizeof *values, compare_doubles);
        /* Drop repeats, which sit next to each other once sorted. */
        size_t distinct = 1;
        for (size_t i = 1; i < n; i++)
            if (values[i] != values[distinct - 1]) values[distinct++] = values[i];

        for (size_t i = 1; i < distinct; i++) {
            double t = (values[i - 1] + values[i]) / 2;
            size_t n_left, n_right;
            partition(days, n, f, t, left, &n_left, right, &n_right);
            double s = (n_left * gini(left, n_left) + n_right * gini(right, n_right)) / n;
            if (!found || s < *score) {
                *score = s; *feature = f; *threshold = t;
                found = true;
            }
        }
    }
    free(values); free(left); free(right);
    return found;
}

static struct node *new_leaf(const struct day *days, size_t n) {
    struct node *leaf = malloc(sizeof *leaf);
    *leaf = (struct node){.left = NULL, .right = NULL, .label = majority(days, n)};
    return leaf;
}

/* Grow a tree on days, calling itself on each side of the best split. */
static struct node *grow(const struct day *days, size_t n, int depth) {
    double g = gini(days, n);
    if (g == 0 || n < MIN_SIZE || depth == MAX_DEPTH) return new_leaf(days, n);

    double score, threshold;
    int f;
    if (!best_split(days, n, &score, &f, &threshold) || score >= g)
        return new_leaf(days, n); /* no split makes the sides purer */

    struct day *left = malloc(n * sizeof *left), *right = malloc(n * sizeof *right);
    size_t n_left, n_right;
    partition(days, n, f, threshold, left, &n_left, right, &n_right);

    struct node *split = malloc(sizeof *split);
    *split = (struct node){.feature = f, .threshold = threshold,
                           .left = grow(left, n_left, depth + 1),
                           .right = grow(right, n_right, depth + 1)};
    free(left); free(right); /* the children keep no pointers into these */
    return split;
}

static bool predict(const struct node *n, const double x[]) {
    while (!is_leaf(n)) n = x[n->feature] <= n->threshold ? n->left : n->right;
    return n->label;
}

/* Print every node, parents before children, left before right. *k is the
 * running node number and *leaves the running leaf count. */
static void print_preorder(const struct node *n, int *k, int *leaves) {
    int id = ++*k;
    if (is_leaf(n)) {
        printf("node_%d_predict %s\n", id, n->label ? "yes" : "no");
        ++*leaves;
        return;
    }
    printf("node_%d_feature %s\n", id, FEATURES[n->feature]);
    printf("node_%d_threshold %.6f\n", id, n->threshold);
    print_preorder(n->left, k, leaves);
    print_preorder(n->right, k, leaves);
}

static size_t count_correct(const struct node *tree, const struct day *days, size_t n) {
    size_t correct = 0;
    for (size_t i = 0; i < n; i++) correct += predict(tree, days[i].x) == days[i].rain;
    return correct;
}

/* Nothing frees memory for you: release the children, then the node. */
static void free_tree(struct node *n) {
    if (!is_leaf(n)) { free_tree(n->left); free_tree(n->right); }
    free(n);
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }

    struct day *train, *test;
    size_t n_train, n_test;
    read_days(argv[1], &train, &n_train, &test, &n_test);
    struct node *tree = grow(train, n_train, 0);

    printf("train_count %zu\n", n_train);
    printf("test_count %zu\n", n_test);
    int k = 0, leaves = 0;
    print_preorder(tree, &k, &leaves);
    printf("leaves %d\n", leaves);

    size_t correct = count_correct(tree, test, n_test);
    printf("train_accuracy %.6f\n", (double)count_correct(tree, train, n_train) / n_train);
    printf("correct %zu\n", correct);
    printf("accuracy %.6f\n", (double)correct / n_test);

    free_tree(tree);
    free(train);
    free(test);
    return 0;
}
