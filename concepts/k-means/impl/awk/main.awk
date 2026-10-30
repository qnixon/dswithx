# k-means clustering (Lloyd's algorithm), in POSIX awk.
#
# Starts from the first K points as centroids, then alternates two steps until
# no point changes cluster: assign each point to its nearest centroid, and move
# each centroid to the mean of its points. Points are stored as they are read;
# the iterations happen in END.

BEGIN { FS = ","; K = 3; MAX_ITERATIONS = 100 }

# The header line: find the x and y columns by name.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        if ($i == "x") xcol = i
        if ($i == "y") ycol = i
    }
    if (!xcol || !ycol) {
        print "missing column x or y" > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

{
    n++
    px[n] = $xcol + 0
    py[n] = $ycol + 0
}

# Squared distance from point i to centroid j.
function dist2(i, j) {
    return (px[i] - cx[j]) ^ 2 + (py[i] - cy[j]) ^ 2
}

# Index of the centroid nearest to point i. The strict "<" means a tie goes
# to the lower index.
function nearest(i,    j, best) {
    best = 1
    for (j = 2; j <= K; j++)
        if (dist2(i, j) < dist2(i, best)) best = j
    return best
}

END {
    if (failed) exit 1

    for (j = 1; j <= K; j++) { cx[j] = px[j]; cy[j] = py[j] }

    # assign[i] starts empty, so the first pass always counts as a change.
    # The pass that changes nothing is counted too, then ends the loop.
    iterations = 0
    while (iterations < MAX_ITERATIONS) {
        iterations++
        changed = 0
        for (i = 1; i <= n; i++) {
            a = nearest(i)
            if (assign[i] != a) { assign[i] = a; changed = 1 }
        }
        if (!changed) break

        # Move each centroid to the mean of its members.
        for (j = 1; j <= K; j++) { sx[j] = 0; sy[j] = 0; size[j] = 0 }
        for (i = 1; i <= n; i++) {
            a = assign[i]
            sx[a] += px[i]; sy[a] += py[i]; size[a]++
        }
        for (j = 1; j <= K; j++)
            if (size[j] > 0) {          # an empty cluster keeps its centroid
                cx[j] = sx[j] / size[j]
                cy[j] = sy[j] / size[j]
            }
    }

    # Sizes and inertia from the final assignment.
    for (j = 1; j <= K; j++) size[j] = 0
    for (i = 1; i <= n; i++) {
        size[assign[i]]++
        inertia += dist2(i, assign[i])
    }

    printf "iterations %d\n", iterations
    for (j = 1; j <= K; j++) {
        printf "centroid_%d_x %.6f\n", j, cx[j]
        printf "centroid_%d_y %.6f\n", j, cy[j]
    }
    for (j = 1; j <= K; j++)
        printf "size_%d %d\n", j, size[j]
    printf "inertia %.6f\n", inertia
}
