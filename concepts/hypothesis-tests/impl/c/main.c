/* Exact two-sided permutation test for a difference in means, using only
 * the C standard library.
 *
 * If compost made no difference, the "compost" and "control" labels are
 * arbitrary, and any 8 of the 16 plants could have carried the compost
 * label. We try every one of those splits and count how many give a
 * difference at least as large as the one we observed. That fraction is
 * the p-value. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_PLANTS 64
#define MAX_LINE 256

/* Every plant's grams, controls first, then compost, in file order. */
static long plants[MAX_PLANTS];
static int plant_count;

/* Running tallies for the enumeration below. */
static long total, threshold;
static long splits, as_extreme;

/* Cut a line at its commas, in place, and return the number of fields.
 * strtok replaces each comma with '\0', so fields[i] points into line. */
static int split(char *line, char *fields[], int max) {
    int n = 0;
    for (char *f = strtok(line, ",\r\n"); f && n < max; f = strtok(NULL, ",\r\n"))
        fields[n++] = f;
    return n;
}

/* Choose `left` more plants from positions start onward, with `chosen`
 * grams already chosen. Each call either takes plant `start` or skips it,
 * so every set of positions is reached exactly once. */
static void choose(int start, int left, long chosen) {
    if (left == 0) {
        long difference = chosen - (total - chosen);
        splits++;
        /* labs is absolute value for a long; whole numbers compare exactly. */
        if (labs(difference) >= threshold) as_extreme++;  /* two-sided */
        return;
    }
    if (plant_count - start < left) return;  /* too few plants remain */
    choose(start + 1, left - 1, chosen + plants[start]);  /* take it */
    choose(start + 1, left, chosen);                       /* skip it */
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }
    FILE *file = fopen(argv[1], "r");
    if (!file) { perror(argv[1]); return 1; }

    char line[MAX_LINE], *fields[4];
    if (!fgets(line, sizeof line, file)) { fprintf(stderr, "empty file\n"); return 1; }

    long control_sum = 0, compost_sum = 0;
    int control_count = 0, compost_count = 0;
    while (fgets(line, sizeof line, file) && plant_count < MAX_PLANTS) {
        if (split(line, fields, 4) != 2) continue;
        long grams = strtol(fields[1], NULL, 10);
        if (strcmp(fields[0], "compost") == 0) {
            compost_sum += grams;
            compost_count++;
        } else {
            control_sum += grams;
            control_count++;
        }
        plants[plant_count++] = grams;
    }
    fclose(file);
    if (compost_count == 0 || compost_count != control_count) {
        fprintf(stderr, "need two groups of equal size\n");
        return 1;
    }

    /* Both groups have the same size, so comparing totals is the same as
     * comparing means, and totals stay whole numbers: no floating-point
     * near-ties. */
    total = control_sum + compost_sum;
    long observed = compost_sum - control_sum;
    threshold = labs(observed);
    choose(0, compost_count, 0);

    printf("control_count %d\n", control_count);
    printf("compost_count %d\n", compost_count);
    printf("control_mean %.6f\n", (double)control_sum / control_count);
    printf("compost_mean %.6f\n", (double)compost_sum / compost_count);
    printf("observed_difference %.6f\n", (double)observed / compost_count);
    printf("splits %ld\n", splits);
    printf("as_extreme %ld\n", as_extreme);
    printf("p_value %.6f\n", (double)as_extreme / splits);
    return 0;
}
