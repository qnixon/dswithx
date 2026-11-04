# 5-fold cross-validation for k-nearest neighbors, using only Base Julia.
#
# Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
# holding out one fold at a time, picks the k with the best average
# accuracy, and then scores that k once on the untouched test seeds.

using Printf

const FOLDS = 5
const KS = 1:2:15  # odd k only, so two varieties can't tie

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

function classify(point, train, k)
    # Julia's default sort is stable, so equal distances keep file order.
    nearest = sort(train, by = seed -> distance(point, seed.point))[1:k]
    votes = Dict{String,Int}()
    for seed in nearest
        votes[seed.variety] = get(votes, seed.variety, 0) + 1
    end
    best = maximum(values(votes))
    return first(seed.variety for seed in nearest if votes[seed.variety] == best)
end

count_correct(points, train, k) =
    count(seed -> classify(seed.point, train, k) == seed.variety, points)

function cv_accuracy(train, k)
    # Fold f (from 0) is rows f*size+1 to (f+1)*size; ranges include both
    # ends. The rows are already shuffled, so consecutive blocks make fair
    # folds. vcat joins the rows before and after the held-out block.
    size = length(train) ÷ FOLDS
    correct = 0
    for f in 0:FOLDS-1
        fold = f*size+1:(f+1)*size
        held_out = train[fold]
        rest = vcat(train[1:first(fold)-1], train[last(fold)+1:end])
        correct += count_correct(held_out, rest, k)
    end
    return correct / length(train)
end

function main(path)
    train, test = read_seeds(path)

    println("train_count $(length(train))")
    println("test_count $(length(test))")
    best_k, best_accuracy = 0, -1.0
    for k in KS
        accuracy = cv_accuracy(train, k)
        @printf("cv_accuracy_k%d %.6f\n", k, accuracy)
        if accuracy > best_accuracy  # strictly better, so ties keep the smaller k
            best_k, best_accuracy = k, accuracy
        end
    end

    # Only now touch the test seeds, once, with the chosen k and all of train.
    correct = count_correct(test, train, best_k)
    println("best_k $best_k")
    println("test_correct $correct")
    @printf("test_accuracy %.6f\n", correct / length(test))
end

main(ARGS[1])
