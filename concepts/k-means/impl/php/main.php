<?php
// k-means clustering (Lloyd's algorithm), using only PHP and the extensions
// built into it.
//
// Starts from the first K points as centroids, then alternates two steps
// until no point changes cluster: assign each point to its nearest centroid,
// and move each centroid to the mean of its points.
declare(strict_types=1);

const K = 3;
const MAX_ITERATIONS = 100;

// Each point is a two-element array [x, y].
function read_points(string $path): array
{
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    array_shift($lines);                 // drop the header row "x,y"
    $points = [];
    foreach ($lines as $line) {
        [$x, $y] = explode(',', $line);  // list-style destructuring
        $points[] = [(float) $x, (float) $y];
    }
    return $points;
}

function squared_distance(array $p, array $q): float
{
    return ($p[0] - $q[0]) ** 2 + ($p[1] - $q[1]) ** 2;
}

// Only a strictly smaller distance replaces the best so far, so a tie goes
// to the lower index. Squared distances rank the same as distances.
function nearest(array $point, array $centroids): int
{
    $best = 0;
    for ($j = 1; $j < count($centroids); $j++) {
        if (squared_distance($point, $centroids[$j]) < squared_distance($point, $centroids[$best])) {
            $best = $j;
        }
    }
    return $best;
}

$points = read_points($argv[1]);

// Assigning an array copies it, so moving a centroid never moves a point.
$centroids = array_slice($points, 0, K);
$assignment = null;
$iterations = 0;
while ($iterations < MAX_ITERATIONS) {
    $iterations++;
    $new = array_map(fn($p) => nearest($p, $centroids), $points);
    // === is true only when both arrays hold the same keys and values, in
    // the same order, with the same types.
    if ($new === $assignment) {
        break;
    }
    $assignment = $new;
    for ($j = 0; $j < K; $j++) {
        $members = array_values(array_filter(
            $points,
            fn($i) => $assignment[$i] === $j,
            ARRAY_FILTER_USE_KEY       // the callback gets each point's index
        ));
        $n = count($members);
        if ($n > 0) {                  // an empty cluster keeps its old centroid
            $centroids[$j] = [
                array_sum(array_column($members, 0)) / $n,
                array_sum(array_column($members, 1)) / $n,
            ];
        }
    }
}

$sizes = array_fill(0, K, 0);
$inertia = 0.0;
foreach ($points as $i => $p) {
    $sizes[$assignment[$i]]++;
    $inertia += squared_distance($p, $centroids[$assignment[$i]]);
}

echo "iterations $iterations\n";
foreach ($centroids as $j => [$x, $y]) {
    printf("centroid_%d_x %.6f\n", $j + 1, $x);
    printf("centroid_%d_y %.6f\n", $j + 1, $y);
}
foreach ($sizes as $j => $size) {
    printf("size_%d %d\n", $j + 1, $size);
}
printf("inertia %.6f\n", $inertia);
