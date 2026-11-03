<?php
// Simple linear regression by least squares, using only PHP and the
// extensions built into it.
//
// Fits score = intercept + slope * hours. PHP has no regression or
// correlation function, so the sums are written out.
declare(strict_types=1);

// Returns the two named columns as lists of floats. The caller unpacks
// the pair with [$xs, $ys] = ...
function read_columns(string $path, string $x_name, string $y_name): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $header = explode(',', array_shift($lines));
    $xcol = array_search($x_name, $header, true);
    $ycol = array_search($y_name, $header, true);
    if ($xcol === false || $ycol === false) {
        throw new RuntimeException("column not found");
    }
    $xs = [];
    $ys = [];
    foreach ($lines as $line) {
        $row = explode(',', $line);
        $xs[] = (float) $row[$xcol];
        $ys[] = (float) $row[$ycol];
    }
    return [$xs, $ys];
}

[$xs, $ys] = read_columns($argv[1], 'hours', 'score');

$n = count($xs);
$mean_x = array_sum($xs) / $n;
$mean_y = array_sum($ys) / $n;

// Sums of squared deviations and of cross-products. Given two arrays,
// array_map walks them side by side, so each x stays paired with its y.
$sxx = array_sum(array_map(fn($x) => ($x - $mean_x) ** 2, $xs));
$syy = array_sum(array_map(fn($y) => ($y - $mean_y) ** 2, $ys));
$sxy = array_sum(array_map(
    fn($x, $y) => ($x - $mean_x) * ($y - $mean_y),
    $xs,
    $ys,
));

$slope = $sxy / $sxx;
$intercept = $mean_y - $slope * $mean_x;
$r = $sxy / sqrt($sxx * $syy);

echo "count $n\n";
printf("slope %.6f\n", $slope);
printf("intercept %.6f\n", $intercept);
printf("r %.6f\n", $r);
printf("r_squared %.6f\n", $r * $r);
