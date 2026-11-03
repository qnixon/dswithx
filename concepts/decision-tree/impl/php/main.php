<?php
// A decision tree classifier (CART with Gini impurity), using only PHP and
// the extensions built into it.
//
// Grows a tree on the training days by always making the split that leaves
// the two sides purest, then predicts rain for the test days. Prints the tree
// in preorder: each node is either a split (feature and threshold) or a leaf
// (its prediction).
declare(strict_types=1);

const FEATURES = ['humidity', 'pressure', 'wind'];
const MAX_DEPTH = 3;
const MIN_SIZE = 5;

// Each day is [[humidity, pressure, wind], label].
function read_days(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $header = array_flip(explode(',', array_shift($lines)));  // name => column
    $train = $test = [];
    foreach ($lines as $line) {
        $row = explode(',', $line);
        $x = array_map(fn($name) => (float) $row[$header[$name]], FEATURES);
        $day = [$x, $row[$header['rain']]];
        if ($row[$header['split']] === 'train') {
            $train[] = $day;
        } else {
            $test[] = $day;
        }
    }
    return [$train, $test];
}

function count_yes(array $labels): int
{
    return count(array_filter($labels, fn($l) => $l === 'yes'));
}

// Chance that two days drawn at random (with replacement) disagree.
function gini(array $labels): float
{
    $p = count_yes($labels) / count($labels);
    return 1 - $p * $p - (1 - $p) * (1 - $p);
}

// An even split predicts "no".
function majority(array $labels): string
{
    return count_yes($labels) > count($labels) / 2 ? 'yes' : 'no';
}

// The [score, feature, threshold] with the lowest weighted Gini impurity, or
// null. Features are tried in column order and thresholds from smallest to
// largest; only a strictly lower score replaces the best so far.
function best_split(array $days): ?array
{
    $best = null;
    foreach (array_keys(FEATURES) as $f) {
        $values = array_map(fn($d) => $d[0][$f], $days);
        sort($values);
        for ($i = 1; $i < count($values); $i++) {
            if ($values[$i] === $values[$i - 1]) {
                continue;  // only midpoints between distinct values
            }
            $threshold = ($values[$i - 1] + $values[$i]) / 2;
            $left = $right = [];
            foreach ($days as [$x, $label]) {
                if ($x[$f] <= $threshold) {
                    $left[] = $label;
                } else {
                    $right[] = $label;
                }
            }
            $score = (count($left) * gini($left) + count($right) * gini($right))
                / count($days);
            if ($best === null || $score < $best[0]) {
                $best = [$score, $f, $threshold];
            }
        }
    }
    return $best;
}

// A leaf is ['leaf' => label]; a split is
// ['feature' => f, 'threshold' => t, 'left' => node, 'right' => node].
function grow(array $days, int $depth = 0): array
{
    $labels = array_column($days, 1);
    if (gini($labels) == 0 || count($days) < MIN_SIZE || $depth === MAX_DEPTH) {
        return ['leaf' => majority($labels)];
    }
    $split = best_split($days);
    if ($split === null || $split[0] >= gini($labels)) {
        return ['leaf' => majority($labels)];  // no split makes the sides purer
    }
    [, $f, $threshold] = $split;
    $left = array_filter($days, fn($d) => $d[0][$f] <= $threshold);
    $right = array_filter($days, fn($d) => $d[0][$f] > $threshold);
    return [
        'feature' => $f,
        'threshold' => $threshold,
        // array_filter keeps the original keys; array_values renumbers them.
        'left' => grow(array_values($left), $depth + 1),
        'right' => grow(array_values($right), $depth + 1),
    ];
}

function predict(array $node, array $x): string
{
    while (!isset($node['leaf'])) {
        $node = $x[$node['feature']] <= $node['threshold'] ? $node['left'] : $node['right'];
    }
    return $node['leaf'];
}

// Appends the node, then its left subtree, then its right subtree.
function preorder(array $node, array &$out): void
{
    $out[] = $node;
    if (!isset($node['leaf'])) {
        preorder($node['left'], $out);
        preorder($node['right'], $out);
    }
}

function accuracy_count(array $tree, array $days): int
{
    return count(array_filter($days, fn($d) => predict($tree, $d[0]) === $d[1]));
}

[$train, $test] = read_days($argv[1]);
$tree = grow($train);

echo 'train_count ', count($train), "\n";
echo 'test_count ', count($test), "\n";
$nodes = [];
preorder($tree, $nodes);
$leaves = 0;
foreach ($nodes as $i => $node) {
    $k = $i + 1;
    if (isset($node['leaf'])) {
        echo "node_{$k}_predict {$node['leaf']}\n";
        $leaves++;
    } else {
        echo "node_{$k}_feature ", FEATURES[$node['feature']], "\n";
        printf("node_%d_threshold %.6f\n", $k, $node['threshold']);
    }
}
echo "leaves $leaves\n";

$correct = accuracy_count($tree, $test);
printf("train_accuracy %.6f\n", accuracy_count($tree, $train) / count($train));
echo "correct $correct\n";
printf("accuracy %.6f\n", $correct / count($test));
