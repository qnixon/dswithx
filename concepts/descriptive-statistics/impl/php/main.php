<?php
// Descriptive statistics on one CSV column, using only PHP and the
// extensions built into it.
//
// PHP has no mean, median, or variance, so each is written out. A PHP array
// is an ordered map; here its keys are 0, 1, 2, and so on, so it acts as a
// list.
declare(strict_types=1);

function read_column(string $path, string $name): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $header = explode(',', array_shift($lines));
    $col = array_search($name, $header, true);
    if ($col === false) {
        throw new RuntimeException("column not found: $name");
    }
    $values = [];
    foreach ($lines as $line) {
        $values[] = (float) explode(',', $line)[$col];
    }
    return $values;
}

function median(array $sorted): float
{
    $n = count($sorted);
    $mid = intdiv($n, 2);
    if ($n % 2 === 1) {
        return $sorted[$mid];
    }
    return ($sorted[$mid - 1] + $sorted[$mid]) / 2;
}

function say(string $name, float $value): void
{
    printf("%s %.6f\n", $name, $value);
}

$values = read_column($argv[1], 'minutes');
sort($values);                       // sorts in place, smallest first

$n = count($values);
$total = array_sum($values);
$mean = $total / $n;

// Sample variance divides by n - 1, not n (Bessel's correction).
$sumsq = array_sum(array_map(fn($v) => ($v - $mean) ** 2, $values));
$variance = $sumsq / ($n - 1);

$min = $values[0];
$max = $values[$n - 1];

echo "count $n\n";
say('sum', $total);
say('mean', $mean);
say('median', median($values));
say('min', $min);
say('max', $max);
say('range', $max - $min);
say('variance', $variance);
say('std_dev', sqrt($variance));
