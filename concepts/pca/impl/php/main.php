<?php
// Principal component analysis by power iteration, using only PHP and the
// extensions built into it.
//
// Standardizes the four scores, builds their correlation matrix, and finds
// the top two eigenvectors (the principal components): power iteration finds
// the first, then deflation removes it from the matrix so the same steps find
// the second.
declare(strict_types=1);

const SUBJECTS = ['math', 'physics', 'reading', 'writing'];
const STEPS = 1000;

// No field is quoted, so explode splits each line on commas. Each row keeps
// the four score columns, in SUBJECTS order.
function read_rows(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $header = explode(',', array_shift($lines));
    $indexes = [];
    foreach (SUBJECTS as $s) {
        $col = array_search($s, $header, true);
        if ($col === false) {
            throw new RuntimeException("column not found: $s");
        }
        $indexes[] = $col;
    }
    return array_map(function ($line) use ($indexes) {
        $fields = explode(',', $line);
        return array_map(fn($i) => (float) $fields[$i], $indexes);
    }, $lines);
}

// Called with two arrays, array_map walks them side by side.
function dot(array $u, array $v): float
{
    return array_sum(array_map(fn($a, $b) => $a * $b, $u, $v));
}

function mat_vec(array $m, array $v): array
{
    return array_map(fn($row) => dot($row, $v), $m);
}

function normalize(array $v): array
{
    $length = sqrt(dot($v, $v));
    return array_map(fn($x) => $x / $length, $v);
}

// Power iteration: multiply by the matrix and rescale, STEPS times.
// Returns the eigenvalue and the eigenvector.
function top_eigenvector(array $m): array
{
    $v = array_fill(0, count($m), 0.0);
    $v[0] = 1.0;
    for ($step = 0; $step < STEPS; $step++) {
        $v = normalize(mat_vec($m, $v));
    }
    // An eigenvector can point either way; make its first entry positive.
    if ($v[0] < 0) {
        $v = array_map(fn($x) => -$x, $v);
    }
    return [dot($v, mat_vec($m, $v)), $v];
}

$rows = read_rows($argv[1]);
$n = count($rows);
$k = count(SUBJECTS);

// Standardize each column to mean 0 and (sample) standard deviation 1.
// array_column pulls out one subject's scores from every row.
$means = [];
$sds = [];
for ($j = 0; $j < $k; $j++) {
    $column = array_column($rows, $j);
    $m = array_sum($column) / $n;
    $means[] = $m;
    $sds[] = sqrt(array_sum(array_map(fn($x) => ($x - $m) ** 2, $column)) / ($n - 1));
}
$z = array_map(
    fn($row) => array_map(fn($x, $m, $s) => ($x - $m) / $s, $row, $means, $sds),
    $rows
);

// The correlation matrix, an array of row arrays: the covariance of the
// standardized columns. $corr[$i][$j] is row i, column j, from 0.
$corr = [];
for ($i = 0; $i < $k; $i++) {
    for ($j = 0; $j < $k; $j++) {
        $corr[$i][$j] = dot(array_column($z, $i), array_column($z, $j)) / ($n - 1);
    }
}

[$value1, $pc1] = top_eigenvector($corr);
// Deflation: subtract the first component's share, leaving the rest.
$deflated = [];
for ($i = 0; $i < $k; $i++) {
    for ($j = 0; $j < $k; $j++) {
        $deflated[$i][$j] = $corr[$i][$j] - $value1 * $pc1[$i] * $pc1[$j];
    }
}
[$value2, $pc2] = top_eigenvector($deflated);

echo "count $n\n";
foreach ([1 => [$value1, $pc1], 2 => [$value2, $pc2]] as $c => [$value, $pc]) {
    printf("eigenvalue_%d %.6f\n", $c, $value);
    // Standardized columns each have variance 1, so the total is k.
    printf("explained_%d %.6f\n", $c, $value / $k);
    foreach (SUBJECTS as $j => $subject) {
        printf("pc%d_%s %.6f\n", $c, $subject, $pc[$j]);
    }
}
printf("student_1_pc1 %.6f\n", dot($z[0], $pc1));
printf("student_1_pc2 %.6f\n", dot($z[0], $pc2));
