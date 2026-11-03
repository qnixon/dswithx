<?php
// Logistic regression by gradient descent, using only PHP and the extensions
// built into it.
//
// Predicts whether a student passed from study hours and sleep. Each feature
// is rescaled with the training rows' mean and standard deviation, then the
// weights start at zero and take STEPS fixed steps of batch gradient descent
// on the average log-loss.
declare(strict_types=1);

const FEATURES = ['hours', 'sleep'];
const LABEL = 'passed';
const LEARNING_RATE = 0.5;
const STEPS = 1000;

// No field is quoted, so explode splits each line on commas. array_combine
// pairs the header names with the fields, giving a row keyed by name.
function read_rows(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $header = explode(',', array_shift($lines));
    return array_map(fn($line) => array_combine($header, explode(',', $line)), $lines);
}

function sigmoid(float $z): float
{
    return 1 / (1 + exp(-$z));
}

function dot(array $a, array $b): float
{
    $total = 0.0;
    foreach ($a as $i => $value) {
        $total += $value * $b[$i];
    }
    return $total;
}

$train = [];
$test = [];
foreach (read_rows($argv[1]) as $row) {
    $x = array_map(fn($f) => (float) $row[$f], FEATURES);
    $example = [$x, (int) $row[LABEL]];
    if ($row['split'] === 'train') {
        $train[] = $example;
    } else {
        $test[] = $example;
    }
}

// Scale each feature to mean 0 and (sample) standard deviation 1, using the
// training rows only.
$means = [];
$sds = [];
foreach (array_keys(FEATURES) as $j) {
    $column = array_map(fn($ex) => $ex[0][$j], $train);
    $m = array_sum($column) / count($column);
    $ss = array_sum(array_map(fn($v) => ($v - $m) ** 2, $column));
    $means[] = $m;
    $sds[] = sqrt($ss / (count($column) - 1));
}

// The leading 1.0 multiplies the intercept. Called with several arrays,
// array_map walks them side by side.
$scale = fn(array $x): array =>
    [1.0, ...array_map(fn($v, $m, $s) => ($v - $m) / $s, $x, $means, $sds)];

$xs = array_map(fn($ex) => $scale($ex[0]), $train);
$ys = array_column($train, 1);
$n = count($xs);

$weights = array_fill(0, count($xs[0]), 0.0);
for ($step = 0; $step < STEPS; $step++) {
    // Gradient of the average log-loss: the mean of (p - y) times each input.
    $gradient = array_fill(0, count($weights), 0.0);
    foreach ($xs as $i => $x) {
        $error = sigmoid(dot($weights, $x)) - $ys[$i];
        foreach ($x as $j => $v) {
            $gradient[$j] += $error * $v / $n;
        }
    }
    // Update every weight only after the whole gradient is known.
    foreach ($gradient as $j => $g) {
        $weights[$j] -= LEARNING_RATE * $g;
    }
}

$loss = 0.0;
foreach ($xs as $i => $x) {
    $p = sigmoid(dot($weights, $x));
    $loss -= $ys[$i] * log($p) + (1 - $ys[$i]) * log(1 - $p);
}
$loss /= $n;

$correct = 0;
foreach ($test as [$x, $y]) {
    $predicted = sigmoid(dot($weights, $scale($x))) >= 0.5 ? 1 : 0;
    if ($predicted === $y) {
        $correct++;
    }
}

echo "train_count $n\n";
echo 'test_count ' . count($test) . "\n";
printf("intercept %.6f\n", $weights[0]);
printf("weight_hours %.6f\n", $weights[1]);
printf("weight_sleep %.6f\n", $weights[2]);
printf("log_loss %.6f\n", $loss);
echo "correct $correct\n";
printf("accuracy %.6f\n", $correct / count($test));
