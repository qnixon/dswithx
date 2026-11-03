<?php
// Categorical naive Bayes with add-one (Laplace) smoothing, using only PHP
// and the extensions built into it.
//
// Learns P(label) and P(feature value | label) by counting training rows,
// then labels each test row with the label that has the highest
// log-probability.
declare(strict_types=1);

const FEATURES = ['has_link', 'mentions_money', 'known_sender'];
const LABEL = 'label';

// Each row becomes an array keyed by column name.
function read_rows(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $names = explode(',', array_shift($lines));
    return array_map(fn($line) => array_combine($names, explode(',', $line)), $lines);
}

$rows = read_rows($argv[1]);
// array_filter keeps the original keys; array_values numbers them from 0.
$train = array_values(array_filter($rows, fn($r) => $r['split'] === 'train'));
$test = array_values(array_filter($rows, fn($r) => $r['split'] === 'test'));

// Reading a missing key warns, so each count starts from ?? 0.
$label_count = [];
$count = [];                           // $count[$label][$feature][$value]
$seen = [];                            // $seen[$feature][$value] = true
foreach ($train as $row) {
    $label = $row[LABEL];
    $label_count[$label] = ($label_count[$label] ?? 0) + 1;
    foreach (FEATURES as $f) {
        $value = $row[$f];
        $count[$label][$f][$value] = ($count[$label][$f][$value] ?? 0) + 1;
        $seen[$f][$value] = true;
    }
}

function log_score(array $row, string $label): float
{
    global $train, $label_count, $count, $seen;
    // Logs turn the product of probabilities into a sum, avoiding underflow.
    $score = log($label_count[$label] / count($train));
    foreach (FEATURES as $f) {
        // Add-one smoothing: an unseen value never gets probability zero.
        $n = ($count[$label][$f][$row[$f]] ?? 0) + 1;
        $score += log($n / ($label_count[$label] + count($seen[$f])));
    }
    return $score;
}

// Labels are tried in alphabetical order, and only a strictly higher score
// wins, so an exact tie goes to the alphabetically first label.
function classify(array $row): string
{
    global $label_count;
    $labels = array_keys($label_count);
    sort($labels);
    $best = $labels[0];
    foreach ($labels as $label) {
        if (log_score($row, $label) > log_score($row, $best)) {
            $best = $label;
        }
    }
    return $best;
}

$correct = count(array_filter($test, fn($r) => classify($r) === $r[LABEL]));

printf("train_count %d\n", count($train));
printf("test_count %d\n", count($test));
printf("correct %d\n", $correct);
printf("accuracy %.6f\n", $correct / count($test));
