# k-nearest neighbors classification, using only Base Julia.
#
# Each test seed is labelled with the majority variety among its K nearest
# training seeds, by Euclidean distance.

using Printf

const K = 5

struct Seed
    point::Vector{Float64}
    variety::String
end

function read_seeds(path)
    train, test = Seed[], Seed[]
    for line in Iterators.drop(eachline(path), 1)  # skip the header
        length_mm, width_mm, variety, split_name = split(line, ",")
        seed = Seed(parse.(Float64, [length_mm, width_mm]), variety)
        push!(split_name == "train" ? train : test, seed)
    end
    return train, test
end

distance(a, b) = sqrt(sum((a .- b) .^ 2))

function classify(point, train)
    # Julia's default sort is stable, so equal distances keep file order.
    nearest = sort(train, by = seed -> distance(point, seed.point))[1:K]
    votes = Dict{String,Int}()
    for seed in nearest
        votes[seed.variety] = get(votes, seed.variety, 0) + 1
    end
    # Pick the most votes; among ties, the variety seen first among the nearest.
    best = maximum(values(votes))
    return first(seed.variety for seed in nearest if votes[seed.variety] == best)
end

function main(path)
    train, test = read_seeds(path)
    correct = count(seed -> classify(seed.point, train) == seed.variety, test)

    println("train_count $(length(train))")
    println("test_count $(length(test))")
    println("correct $correct")
    @printf("accuracy %.6f\n", correct / length(test))
end

main(ARGS[1])
