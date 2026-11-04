<?php
// Evaluation metrics for a binary classifier, using only PHP and the
// extensions built into it.
//
// Reads each part's true label and the model's score, then reports the
// confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
// the accuracy of never flagging anything, and the area under the ROC curve.
declare(strict_types=1);

// Returns a list of parts, each [bool defective, float score].
function read_parts(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $col = array_flip(explode(',', array_shift($lines)));   // name => position
    $parts = [];
    foreach ($lines as $line) {
        $row = explode(',', $line);
        $parts[] = [$row[$col['defective']] === '1', (float) $row[$col['score']]];
    }
    return $parts;
}

function report(array $parts, string $suffix, float $threshold): void
{
    // A part is flagged when its score reaches the threshold.
    $tp = $fp = $fn = $tn = 0;
    foreach ($parts as [$defective, $score]) {
        $flagged = $score >= $threshold;
        if ($flagged && $defective) {
            $tp++;
        } elseif ($flagged) {
            $fp++;
        } elseif ($defective) {
            $fn++;
        } else {
            $tn++;
        }
    }

    $accuracy = ($tp + $tn) / count($parts);
    $precision = $tp / ($tp + $fp);   // of the flagged parts, how many are defective
    $recall = $tp / ($tp + $fn);      // of the defective parts, how many are flagged
    $f1 = 2 * $precision * $recall / ($precision + $recall);

    echo "tp_at_$suffix $tp\n";
    echo "fp_at_$suffix $fp\n";
    echo "fn_at_$suffix $fn\n";
    echo "tn_at_$suffix $tn\n";
    printf("accuracy_at_%s %.6f\n", $suffix, $accuracy);
    printf("precision_at_%s %.6f\n", $suffix, $precision);
    printf("recall_at_%s %.6f\n", $suffix, $recall);
    printf("f1_at_%s %.6f\n", $suffix, $f1);
}

// The chance that a random defective part outscores a random good one.
// Compare every pair, scoring 2 for a win and 1 for a tie, so the count
// stays a whole number until the final division. The spaceship operator
// <=> returns 1, 0, or -1, so adding 1 gives 2, 1, or 0 points.
function auc(array $parts): float
{
    $defective = [];
    $good = [];
    foreach ($parts as [$is_defective, $score]) {
        if ($is_defective) {
            $defective[] = $score;
        } else {
            $good[] = $score;
        }
    }
    $points = 0;
    foreach ($defective as $d) {
        foreach ($good as $g) {
            $points += ($d <=> $g) + 1;
        }
    }
    return $points / (2 * count($defective) * count($good));
}

$parts = read_parts($argv[1]);
$defective = count(array_filter($parts, fn($part) => $part[0]));

echo 'parts ', count($parts), "\n";
echo "defective $defective\n";
// Never flagging anything is right about every good part.
printf("baseline_accuracy %.6f\n", (count($parts) - $defective) / count($parts));
report($parts, '50', 0.5);
report($parts, '30', 0.3);
printf("auc %.6f\n", auc($parts));
