/* Evaluation metrics for a binary classifier, using only the C standard
 * library.
 *
 * Reads each part's true label and the model's score, then reports the
 * confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
 * the accuracy of never flagging anything, and the area under the ROC
 * curve. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_PARTS 1000
#define MAX_LINE 256

static int defective[MAX_PARTS];   /* 1 for a defective part, 0 for a good one */
static double score[MAX_PARTS];
static int part_count;

/* Cut a line at its commas, in place, and return the number of fields.
 * strtok replaces each comma with '\0', so fields[i] points into line. */
static int split(char *line, char *fields[], int max) {
    int n = 0;
    for (char *f = strtok(line, ",\r\n"); f && n < max; f = strtok(NULL, ",\r\n"))
        fields[n++] = f;
    return n;
}

/* Sort every part into one of four counts at this threshold, then print
 * the counts and the ratios built from them. */
static void report(const char *suffix, double threshold) {
    int tp = 0, fp = 0, fn = 0, tn = 0;
    for (int i = 0; i < part_count; i++) {
        int flagged = score[i] >= threshold;  /* flagged when the score reaches it */
        if (flagged && defective[i]) tp++;
        else if (flagged) fp++;
        else if (defective[i]) fn++;
        else tn++;
    }
    /* Casting one side to double makes the division a real one; int / int
     * would throw away the fraction. */
    double accuracy = (double)(tp + tn) / part_count;
    double precision = (double)tp / (tp + fp);  /* of the flagged, how many defective */
    double recall = (double)tp / (tp + fn);     /* of the defective, how many flagged */
    double f1 = 2 * precision * recall / (precision + recall);

    printf("tp_at_%s %d\n", suffix, tp);
    printf("fp_at_%s %d\n", suffix, fp);
    printf("fn_at_%s %d\n", suffix, fn);
    printf("tn_at_%s %d\n", suffix, tn);
    printf("accuracy_at_%s %.6f\n", suffix, accuracy);
    printf("precision_at_%s %.6f\n", suffix, precision);
    printf("recall_at_%s %.6f\n", suffix, recall);
    printf("f1_at_%s %.6f\n", suffix, f1);
}

/* The chance that a random defective part outscores a random good one.
 * Compare every pair, scoring 2 for a win and 1 for a tie, so the count
 * stays a whole number until the final division. */
static double auc(void) {
    long points = 0, pairs = 0;
    for (int d = 0; d < part_count; d++) {
        if (!defective[d]) continue;
        for (int g = 0; g < part_count; g++) {
            if (defective[g]) continue;
            pairs++;
            if (score[d] > score[g]) points += 2;
            else if (score[d] == score[g]) points += 1;  /* same text, same double */
        }
    }
    return (double)points / (2 * pairs);
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s data.csv\n", argv[0]); return 1; }
    FILE *file = fopen(argv[1], "r");
    if (!file) { perror(argv[1]); return 1; }

    char line[MAX_LINE], *fields[4];
    if (!fgets(line, sizeof line, file)) { fprintf(stderr, "empty file\n"); return 1; }

    int defective_count = 0;
    while (fgets(line, sizeof line, file) && part_count < MAX_PARTS) {
        if (split(line, fields, 4) != 2) continue;
        defective[part_count] = strcmp(fields[0], "1") == 0;
        score[part_count] = strtod(fields[1], NULL);
        defective_count += defective[part_count];
        part_count++;
    }
    fclose(file);

    printf("parts %d\n", part_count);
    printf("defective %d\n", defective_count);
    /* Never flagging anything is right about every good part. */
    printf("baseline_accuracy %.6f\n", (double)(part_count - defective_count) / part_count);
    report("50", 0.5);
    report("30", 0.3);
    printf("auc %.6f\n", auc());
    return 0;
}
