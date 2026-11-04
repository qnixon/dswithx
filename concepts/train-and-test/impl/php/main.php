<?php
// Train and test error for polynomials of degree 1 to 8, using only PHP and
// the extensions built into it.
//
// Each polynomial is fitted by least squares to the training drives only: we
// build the normal equations and solve them by Gaussian elimination. Then we
// measure its root-mean-square error on the training drives and on the test
// drives it never saw. A matrix is an array of row arrays.
declare(strict_types=1);

const MAX_DEGREE = 8;

// No field is quoted, so explode splits each line on commas. Returns the
// training drives and the test drives, each a list of [speed, litres].
function read_drives(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $header = explode(',', array_shift($lines));
    $train = [];
    $test = [];
    foreach ($lines as $line) {
        // array_combine pairs each header name with its field.
        $row = array_combine($header, explode(',', $line));
        $point = [(float) $row['speed'], (float) $row['litres']];
        if ($row['split'] === 'train') {
            $train[] = $point;
        } else {
            $test[] = $point;
        }
    }
    return [$train, $test];
}

// Solve a x = b by Gaussian elimination with partial pivoting. PHP passes
// arrays by value, so changing $m here leaves the caller's copy alone.
function solve(array $a, array $b): array
{
    $n = count($b);
    $m = [];  // the augmented matrix: b is column n
    foreach ($a as $i => $row) {
        $m[] = [...$row, $b[$i]];
    }
    for ($col = 0; $col < $n; $col++) {
        // Swap up the row with the largest entry in this column, which keeps
        // the rounding error small.
        $pivot = $col;
        for ($r = $col + 1; $r < $n; $r++) {
            if (abs($m[$r][$col]) > abs($m[$pivot][$col])) {
                $pivot = $r;
            }
        }
        [$m[$col], $m[$pivot]] = [$m[$pivot], $m[$col]];
        for ($r = $col + 1; $r < $n; $r++) {
            $factor = $m[$r][$col] / $m[$col][$col];
            for ($c = $col; $c <= $n; $c++) {
                $m[$r][$c] -= $factor * $m[$col][$c];
            }
        }
    }
    // Back substitution, from the last unknown up.
    $x = array_fill(0, $n, 0.0);
    for ($r = $n - 1; $r >= 0; $r--) {
        $total = $m[$r][$n];
        for ($c = $r + 1; $c < $n; $c++) {
            $total -= $m[$r][$c] * $x[$c];
        }
        $x[$r] = $total / $m[$r][$r];
    }
    return $x;
}

// Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
// Z is 1, z_i, z_i^2, ..., z_i^degree.
function fit(array $points, int $degree, callable $scale): array
{
    $size = $degree + 1;
    $a = array_fill(0, $size, array_fill(0, $size, 0.0));
    $b = array_fill(0, $size, 0.0);
    foreach ($points as [$x, $y]) {
        $z = $scale($x);
        for ($i = 0; $i < $size; $i++) {
            $b[$i] += $y * $z ** $i;
            for ($j = 0; $j < $size; $j++) {
                $a[$i][$j] += $z ** ($i + $j);
            }
        }
    }
    return solve($a, $b);
}

function rmse(array $coefs, array $points, callable $scale): float
{
    $total = 0.0;
    foreach ($points as [$x, $y]) {
        $z = $scale($x);
        $predicted = 0.0;
        foreach ($coefs as $i => $c) {
            $predicted += $c * $z ** $i;
        }
        $total += ($predicted - $y) ** 2;
    }
    return sqrt($total / count($points));
}

[$train, $test] = read_drives($argv[1]);

// Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
// largest entry at degree 8) would swamp the small ones and make the
// equations hard to solve accurately.
$speeds = array_column($train, 0);
$low = min($speeds);
$high = max($speeds);
$mid = ($low + $high) / 2;
$half = ($high - $low) / 2;
$scale = fn(float $x): float => ($x - $mid) / $half;  // fn captures $mid and $half

printf("train_count %d\n", count($train));
printf("test_count %d\n", count($test));
$train_errors = [];
$test_errors = [];
for ($degree = 1; $degree <= MAX_DEGREE; $degree++) {
    $coefs = fit($train, $degree, $scale);
    $train_errors[$degree] = rmse($coefs, $train, $scale);
    $test_errors[$degree] = rmse($coefs, $test, $scale);
}
foreach ($train_errors as $degree => $e) {
    printf("train_rmse_d%d %.6f\n", $degree, $e);
}
foreach ($test_errors as $degree => $e) {
    printf("test_rmse_d%d %.6f\n", $degree, $e);
}
