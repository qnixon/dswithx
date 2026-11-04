# Exact two-sided permutation test for a difference in means, in POSIX awk.
#
# If compost made no difference, the "compost" and "control" labels are
# arbitrary, and any 8 of the 16 plants could have carried the compost label.
# We try every one of those splits and count how many give a difference at
# least as large as the one we observed. That fraction is the p-value. Rows
# are stored as they are read; the work happens in END.

BEGIN { FS = "," }

# The header line: find each column by name.
NR == 1 {
    for (i = 1; i <= NF; i++) {
        if ($i == "group") c_group = i
        if ($i == "grams") c_grams = i
    }
    if (!c_group || !c_grams) {
        print "missing a column (group, grams)" > "/dev/stderr"
        failed = 1
        exit 1
    }
    next
}

# Every plant goes into one array; the group totals are kept as we go.
{
    n_plants++
    plant[n_plants] = $c_grams + 0
    if ($c_group == "control") { n_control++; control_total += $c_grams }
    if ($c_group == "compost") { n_compost++; compost_total += $c_grams }
}

function abs(x) { return x < 0 ? -x : x }

# Walk every way to pick `left` more plants from position start onward,
# carrying the running total of the plants picked so far. awk functions can
# call themselves, and i is local (declared as an extra parameter), so each
# call keeps its own loop counter.
function choose(start, left, chosen_total,    i, difference) {
    if (left == 0) {
        difference = chosen_total - (total - chosen_total)
        splits++
        if (abs(difference) >= abs(observed)) as_extreme++   # two-sided
        return
    }
    # Stop early enough that `left` plants still remain to pick.
    for (i = start; i <= n_plants - left + 1; i++)
        choose(i + 1, left - 1, chosen_total + plant[i])
}

END {
    if (failed) exit 1
    total = control_total + compost_total

    # Both groups have the same size, so comparing totals is the same as
    # comparing means. The totals are whole numbers, and awk's doubles hold
    # whole numbers this size exactly, so >= never meets a near-tie.
    observed = compost_total - control_total
    choose(1, n_compost, 0)

    printf "control_count %d\n", n_control
    printf "compost_count %d\n", n_compost
    printf "control_mean %.6f\n", control_total / n_control
    printf "compost_mean %.6f\n", compost_total / n_compost
    printf "observed_difference %.6f\n", observed / n_compost
    printf "splits %d\n", splits
    printf "as_extreme %d\n", as_extreme
    printf "p_value %.6f\n", as_extreme / splits
}
