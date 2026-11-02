/* k-means clustering (Lloyd's algorithm), using only the C standard library.
 *
 * Starts from the first K points as centroids, then alternates two steps until
 * no point changes cluster: assign each point to its nearest centroid, and move
 * each centroid to the mean of its points. */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define K 3
#define MAX_ITERATIONS 100
#define MAX_LINE 1024

/* A struct groups the two coordinates, so a point can be copied with =. */
typedef struct { double x, y; } Point;

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

/* Read the x and y columns as points. The array doubles in size whenever it
 * fills, and the count comes back through *count. */
static Point *read_points(const char *path, size_t *count) {
    FILE *file = fopen(path, "r");
    if (!file) { perror(path); exit(1); }

    char line[MAX_LINE];
    if (!fgets(line, sizeof line, file)) { fprintf(stderr, "empty file\n"); exit(1); }
    int x_col = column_index(line, "x"), y_col = column_index(line, "y");
    if (x_col < 0 || y_col < 0) { fprintf(stderr, "no x or y column\n"); exit(1); }

    size_t n = 0, capacity = 64;
    Point *points = malloc(capacity * sizeof *points);
    while (fgets(line, sizeof line, file)) {
        Point p = {0, 0};
        int index = 0;
        for (char *field = strtok(line, ",\r\n"); field; field = strtok(NULL, ",\r\n")) {
            if (index == x_col) p.x = strtod(field, NULL);
            if (index == y_col) p.y = strtod(field, NULL);
            index++;
        }
        if (index == 0) continue;   /* a blank line */
        if (n == capacity) {
            capacity *= 2;
            points = realloc(points, capacity * sizeof *points);
        }
        points[n++] = p;
    }
    fclose(file);
    *count = n;
    return points;
}

/* Squared Euclidean distance. It ranks centroids in the same order as the
 * distance itself, so the nearest one needs no sqrt. */
static double squared_distance(Point a, Point b) {
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
}

/* The index of the closest centroid. Only a strictly smaller distance
 * replaces the best so far, so a tie goes to the lower index. */
static int nearest(Point p, const Point centroids[K]) {
    int best = 0;
    for (int j = 1; j < K; j++)
        if (squared_distance(p, centroids[j]) < squared_distance(p, centroids[best])) best = j;
    return best;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }

    size_t n;
    Point *points = read_points(argv[1], &n);
    if (n < K) { fprintf(stderr, "need at least %d points\n", K); return 1; }

    Point centroids[K];
    for (int j = 0; j < K; j++) centroids[j] = points[j];   /* copies, not views */

    /* -1 means "no cluster yet", so the first pass always counts as a change. */
    int *assignment = malloc(n * sizeof *assignment);
    for (size_t i = 0; i < n; i++) assignment[i] = -1;

    int iterations = 0;
    while (iterations < MAX_ITERATIONS) {
        iterations++;
        int changed = 0;   /* C treats 0 as false and anything else as true */
        for (size_t i = 0; i < n; i++) {
            int j = nearest(points[i], centroids);
            if (j != assignment[i]) { assignment[i] = j; changed = 1; }
        }
        if (!changed) break;

        /* Sum each cluster's points in one pass, then divide by its size. */
        Point sums[K] = {{0, 0}};   /* elements left out of an initializer start at 0 */
        int sizes[K] = {0};
        for (size_t i = 0; i < n; i++) {
            sums[assignment[i]].x += points[i].x;
            sums[assignment[i]].y += points[i].y;
            sizes[assignment[i]]++;
        }
        for (int j = 0; j < K; j++)
            if (sizes[j] > 0)   /* an empty cluster keeps its old centroid */
                centroids[j] = (Point){sums[j].x / sizes[j], sums[j].y / sizes[j]};
    }

    int sizes[K] = {0};
    double inertia = 0;
    for (size_t i = 0; i < n; i++) {
        sizes[assignment[i]]++;
        inertia += squared_distance(points[i], centroids[assignment[i]]);
    }

    /* Clusters are numbered from 0 inside C and from 1 in the output. */
    printf("iterations %d\n", iterations);
    for (int j = 0; j < K; j++) {
        printf("centroid_%d_x %.6f\n", j + 1, centroids[j].x);
        printf("centroid_%d_y %.6f\n", j + 1, centroids[j].y);
    }
    for (int j = 0; j < K; j++) printf("size_%d %d\n", j + 1, sizes[j]);
    printf("inertia %.6f\n", inertia);

    free(assignment);
    free(points);
    return 0;
}
