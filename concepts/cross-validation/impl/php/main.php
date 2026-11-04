<?php
// 5-fold cross-validation for k-nearest neighbors, using only PHP and the
// extensions built into it.
//
// Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
// holding out one fold at a time, picks the k with the best average
// accuracy, and then scores that k once on the untouched test seeds.
declare(strict_types=1);

const FOLDS = 5;

// Each seed becomes an array with string keys, a small record:
// ['len' => 5.5, 'wid' => 3.11, 'label' => 'kama'].
function read_seeds(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $col = array_flip(explode(',', array_shift($lines)));   // name => position
    $train = [];
    $test = [];
    foreach ($lines as $line) {
        $row = explode(',', $line);
        $seed = [
            'len'   => (float) $row[$col['length_mm']],
            'wid'   => (float) $row[$col['width_mm']],
            'label' => $row[$col['variety']],
        ];
        if ($row[$col['split']] === 'train') {
            $train[] = $seed;
        } else {
            $test[] = $seed;
        }
    }
    return [$train, $test];
}

function classify(array $point, array $train, int $k): string
{
    // Pair each training seed's distance with its row number.
    $scored = [];
    foreach ($train as $row => $seed) {
        $d = sqrt(($point['len'] - $seed['len']) ** 2
                + ($point['wid'] - $seed['wid']) ** 2);
        $scored[] = ['d' => $d, 'row' => $row, 'label' => $seed['label']];
    }

    // <=> returns -1, 0, or 1. On equal distances ?: falls through to the
    // row number, so the earlier training seed comes first.
    usort($scored, fn($a, $b) => ($a['d'] <=> $b['d']) ?: ($a['row'] <=> $b['row']));
    $nearest = array_slice($scored, 0, $k);

    // Count votes in an array keyed by label; ?? 0 supplies the first count.
    // With two varieties and odd k, no vote ties.
    $votes = [];
    $best = null;
    foreach ($nearest as $seed) {
        $label = $seed['label'];
        $votes[$label] = ($votes[$label] ?? 0) + 1;
        if ($best === null || $votes[$label] > $votes[$best]) {
            $best = $label;
        }
    }
    return $best;
}

function count_correct(array $points, array $train, int $k): int
{
    $correct = 0;
    foreach ($points as $seed) {
        if (classify($seed, $train, $k) === $seed['label']) {
            $correct++;
        }
    }
    return $correct;
}

function cv_accuracy(array $train, int $k): float
{
    // Fold f is rows f*size up to (f+1)*size. The rows are already
    // shuffled, so consecutive blocks make fair folds. array_slice takes
    // (start, length) and numbers the copy from 0 again.
    $size = intdiv(count($train), FOLDS);
    $correct = 0;
    for ($f = 0; $f < FOLDS; $f++) {
        $held_out = array_slice($train, $f * $size, $size);
        $rest = array_merge(array_slice($train, 0, $f * $size),
                            array_slice($train, ($f + 1) * $size));
        $correct += count_correct($held_out, $rest, $k);
    }
    return $correct / count($train);
}

[$train, $test] = read_seeds($argv[1]);

echo 'train_count ', count($train), "\n";
echo 'test_count ', count($test), "\n";
$best_k = 0;
$best_accuracy = -1.0;
for ($k = 1; $k <= 15; $k += 2) {   // odd k only
    $accuracy = cv_accuracy($train, $k);
    printf("cv_accuracy_k%d %.6f\n", $k, $accuracy);
    if ($accuracy > $best_accuracy) {   // strictly better: ties keep the smaller k
        $best_k = $k;
        $best_accuracy = $accuracy;
    }
}

// Only now touch the test seeds, once, with the chosen k and all of train.
$correct = count_correct($test, $train, $best_k);
echo "best_k $best_k\n";
echo "test_correct $correct\n";
printf("test_accuracy %.6f\n", $correct / count($test));
