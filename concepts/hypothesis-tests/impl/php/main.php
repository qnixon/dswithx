<?php
// Exact two-sided permutation test for a difference in means, using only
// PHP and the extensions built into it.
//
// If compost made no difference, the "compost" and "control" labels are
// arbitrary, and any n of the plants could have carried the compost label.
// We try every one of those splits and count how many give a difference at
// least as large as the one we observed. That fraction is the p-value.
declare(strict_types=1);

// Returns [control grams, compost grams] as two lists of integers.
function read_groups(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $col = array_flip(explode(',', array_shift($lines)));   // name => position
    $groups = ['control' => [], 'compost' => []];
    foreach ($lines as $line) {
        $row = explode(',', $line);
        $groups[$row[$col['group']]][] = (int) $row[$col['grams']];
    }
    return [$groups['control'], $groups['compost']];
}

// Yields the compost total of every way to choose $left more plants from
// position $next on; $chosen is the total of those picked so far. Each step
// either takes plant $next or skips it, so every choice is reached once. A
// function with yield is a generator: foreach pulls one value at a time,
// and yield from passes along everything a nested call yields.
function chosen_totals(array $plants, int $next, int $left, int $chosen): Generator
{
    if ($left === 0) {
        yield $chosen;
        return;
    }
    if (count($plants) - $next < $left) {
        return;   // too few plants left to finish this choice
    }
    yield from chosen_totals($plants, $next + 1, $left - 1, $chosen + $plants[$next]);
    yield from chosen_totals($plants, $next + 1, $left, $chosen);
}

[$control, $compost] = read_groups($argv[1]);
$n = count($compost);
$plants = array_merge($control, $compost);
$total = array_sum($plants);

// Both groups have n plants, so comparing totals is the same as comparing
// means, and totals stay whole numbers: no floating-point near-ties.
$observed = array_sum($compost) - array_sum($control);

$splits = 0;
$as_extreme = 0;
foreach (chosen_totals($plants, 0, $n, 0) as $relabeled) {
    $splits++;
    // Two-sided: abs counts a difference in either direction.
    if (abs($relabeled - ($total - $relabeled)) >= abs($observed)) {
        $as_extreme++;
    }
}

echo 'control_count ', count($control), "\n";
echo "compost_count $n\n";
printf("control_mean %.6f\n", array_sum($control) / count($control));
printf("compost_mean %.6f\n", array_sum($compost) / $n);
printf("observed_difference %.6f\n", $observed / $n);
echo "splits $splits\n";
echo "as_extreme $as_extreme\n";
printf("p_value %.6f\n", $as_extreme / $splits);
