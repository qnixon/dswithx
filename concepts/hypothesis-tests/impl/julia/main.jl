# Exact two-sided permutation test for a difference in means, using only
# Base Julia.
#
# If compost made no difference, the "compost" and "control" labels are
# arbitrary, and any 8 of the 16 plants could have carried the compost label.
# We try every one of those splits and count how many give a difference at
# least as large as the one we observed. That fraction is the p-value.

using Printf

function read_groups(path)
    groups = Dict("control" => Int[], "compost" => Int[])
    for line in Iterators.drop(eachline(path), 1)  # skip the header
        group, grams = split(line, ",")
        push!(groups[group], parse(Int, grams))
    end
    return groups["control"], groups["compost"]
end

function main(path)
    control, compost = read_groups(path)
    n = length(compost)
    plants = vcat(control, compost)
    total = sum(plants)

    # Both groups have n plants, so comparing totals is the same as comparing
    # means, and totals stay whole numbers: no floating-point near-ties.
    observed = sum(compost) - sum(control)

    # Each split is a number whose binary digits mark the chosen plants: bit
    # i - 1 set means plant i carries the compost label. Of the 2^16 numbers,
    # the ones with exactly n bits set are the splits.
    splits = 0
    as_extreme = 0
    for mask in 0:(1 << length(plants)) - 1
        count_ones(mask) == n || continue
        relabeled = sum(plants[i] for i in eachindex(plants) if (mask >> (i - 1)) & 1 == 1)
        difference = relabeled - (total - relabeled)
        splits += 1
        if abs(difference) >= abs(observed)  # two-sided
            as_extreme += 1
        end
    end

    println("control_count $(length(control))")
    println("compost_count $n")
    @printf("control_mean %.6f\n", sum(control) / length(control))
    @printf("compost_mean %.6f\n", sum(compost) / n)
    @printf("observed_difference %.6f\n", observed / n)
    println("splits $splits")
    println("as_extreme $as_extreme")
    @printf("p_value %.6f\n", as_extreme / splits)
end

main(ARGS[1])
