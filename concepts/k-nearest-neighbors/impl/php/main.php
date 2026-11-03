<?php
// k-nearest neighbors classification, using only PHP and the extensions
// built into it.
//
// Each test seed is labelled with the majority variety among its K nearest
// training seeds, by Euclidean distance. PHP has no kNN or distance
// function, so both are written out.
declare(strict_types=1);

const K = 5;

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

function classify(array $point, array $train): string
{
    // Pair each training seed's distance with its row number.
    $scored = [];
    foreach ($train as $row => $seed) {
        $d = sqrt(($point['len'] - $seed['len']) ** 2
                + ($point['wid'] - $seed['wid']) ** 2);
        $scored[] = ['d' => $d, 'row' => $row, 'label' => $seed['label']];
    }

    // <=> returns -1, 0, or 1. When distances are equal it returns 0, and
    // ?: falls through to the row number, so equal distances keep the
    // earlier training seed. PHP 8's sort is stable anyway, but the tie
    // rule is now written in the code.
    usort($scored, fn($a, $b) => ($a['d'] <=> $b['d']) ?: ($a['row'] <=> $b['row']));
    $nearest = array_slice($scored, 0, K);

    // Count votes in an array keyed by label. ++ on a missing key warns,
    // so ?? 0 supplies the starting count. With two varieties and odd K,
    // no vote ties.
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

[$train, $test] = read_seeds($argv[1]);

$correct = 0;
foreach ($test as $seed) {
    if (classify($seed, $train) === $seed['label']) {
        $correct++;
    }
}

echo 'train_count ', count($train), "\n";
echo 'test_count ', count($test), "\n";
echo "correct $correct\n";
printf("accuracy %.6f\n", $correct / count($test));
