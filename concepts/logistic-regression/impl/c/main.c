/* Logistic regression by gradient descent, using only the C standard library.
 *
 * Predicts whether a student passed from study hours and sleep. Each feature
 * is rescaled with the training rows' mean and standard deviation, then the
 * weights start at zero and take STEPS fixed steps of batch gradient descent
 * on the average log-loss. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE 1024
#define MAX_FIELDS 16
#define K 3 /* inputs per row: 1 (for the intercept), hours, sleep */
#define LEARNING_RATE 0.5
#define STEPS 1000

/* One student: x[0] is always 1, so weight 0 acts as the intercept. */
struct example {
    double x[K];
    int y;
};

/* A growable array of examples; C has no built-in list. */
struct examples {
    struct example *rows;
    size_t n, capacity;
};

static void append(struct examples *set, struct example row) {
    if (set->n == set->capacity) {
        set->capacity = set->capacity ? set->capacity * 2 : 64;
        set->rows = realloc(set->rows, set->capacity * sizeof *set->rows);
    }
    set->rows[set->n++] = row;
}

/* Cut a line at its commas into fields[], returning how many there are.
 * strtok writes '\0' over each comma, so the fields point into line. */
static int split(char *line, char *fields[]) {
    int count = 0;
    for (char *f = strtok(line, ",\r\n"); f && count < MAX_FIELDS; f = strtok(NULL, ",\r\n"))
        fields[count++] = f;
    return count;
}

/* Return the 0-based position of name among the header fields. */
static int column(char *header[], int count, const char *name) {
    for (int i = 0; i < count; i++)
        if (strcmp(header[i], name) == 0) return i;
    fprintf(stderr, "no column %s\n", name);
    exit(1);
}

/* Read the CSV into training and test rows, sorted by the "split" column. */
static void read_rows(const char *path, struct examples *train, struct examples *test) {
    FILE *file = fopen(path, "r");
    if (!file) { perror(path); exit(1); }

    char header[MAX_LINE], line[MAX_LINE];
    char *fields[MAX_FIELDS];
    if (!fgets(header, sizeof header, file)) { fprintf(stderr, "empty file\n"); exit(1); }
    int count = split(header, fields);
    int c_hours = column(fields, count, "hours"), c_sleep = column(fields, count, "sleep");
    int c_passed = column(fields, count, "passed"), c_split = column(fields, count, "split");

    while (fgets(line, sizeof line, file)) {
        if (split(line, fields) < count) continue;
        struct example row = {{1.0, strtod(fields[c_hours], NULL), strtod(fields[c_sleep], NULL)},
                              atoi(fields[c_passed])};
        append(strcmp(fields[c_split], "train") == 0 ? train : test, row);
    }
    fclose(file);
}

static double sigmoid(double z) { return 1 / (1 + exp(-z)); }

/* The probability of passing: the sigmoid of the weighted sum of inputs. */
static double predict(const double w[K], const double x[K]) {
    double z = 0;
    for (int j = 0; j < K; j++) z += w[j] * x[j];
    return sigmoid(z);
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }

    struct examples train = {0}, test = {0}; /* {0} sets every field to zero */
    read_rows(argv[1], &train, &test);
    size_t n = train.n;

    /* Scale each feature to mean 0 and (sample) standard deviation 1, using
     * the training rows only, then apply the same shift to the test rows.
     * Column 0 holds the ones, so the features are columns 1 and 2. */
    for (int j = 1; j < K; j++) {
        double total = 0, squares = 0;
        for (size_t i = 0; i < n; i++) total += train.rows[i].x[j];
        double mean = total / n;
        for (size_t i = 0; i < n; i++) {
            double d = train.rows[i].x[j] - mean;
            squares += d * d;
        }
        double sd = sqrt(squares / (n - 1));
        for (size_t i = 0; i < n; i++) train.rows[i].x[j] = (train.rows[i].x[j] - mean) / sd;
        for (size_t i = 0; i < test.n; i++) test.rows[i].x[j] = (test.rows[i].x[j] - mean) / sd;
    }

    double w[K] = {0};
    for (int step = 0; step < STEPS; step++) {
        /* Gradient of the average log-loss: the mean of (p - y) times each
         * input. It is summed over every student before any weight moves. */
        double gradient[K] = {0};
        for (size_t i = 0; i < n; i++) {
            double error = predict(w, train.rows[i].x) - train.rows[i].y;
            for (int j = 0; j < K; j++) gradient[j] += error * train.rows[i].x[j];
        }
        for (int j = 0; j < K; j++) w[j] -= LEARNING_RATE * gradient[j] / n;
    }

    double loss = 0;
    for (size_t i = 0; i < n; i++) {
        double p = predict(w, train.rows[i].x);
        loss -= train.rows[i].y ? log(p) : log(1 - p);
    }
    loss /= n;

    int correct = 0;
    for (size_t i = 0; i < test.n; i++)
        correct += (predict(w, test.rows[i].x) >= 0.5) == test.rows[i].y;

    printf("train_count %zu\n", n);
    printf("test_count %zu\n", test.n);
    printf("intercept %.6f\n", w[0]);
    printf("weight_hours %.6f\n", w[1]);
    printf("weight_sleep %.6f\n", w[2]);
    printf("log_loss %.6f\n", loss);
    printf("correct %d\n", correct);
    /* Cast before dividing, or 37 / 50 is integer division and gives 0. */
    printf("accuracy %.6f\n", (double)correct / test.n);

    free(train.rows);
    free(test.rows);
    return 0;
}
