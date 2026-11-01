# Logistic regression by gradient descent, using only Base Julia.
#
# Predicts whether a student passed from study hours and sleep. Each feature is
# rescaled with the training rows' mean and standard deviation, then the weights
# start at zero and take STEPS fixed steps of batch gradient descent on the
# average log-loss.

using Printf

const LEARNING_RATE = 0.5
const STEPS = 1000

function read_students(path)
    train, test = Vector{Float64}[], Vector{Float64}[]
    for line in Iterators.drop(eachline(path), 1)  # skip the header
        hours, sleep, passed, split_name = split(line, ",")
        row = parse.(Float64, [hours, sleep, passed])
        push!(split_name == "train" ? train : test, row)
    end
    # Stack the rows into matrices: one row per student, columns hours, sleep, passed.
    return reduce(vcat, permutedims.(train)), reduce(vcat, permutedims.(test))
end

sigmoid(z) = 1 / (1 + exp(-z))

function main(path)
    train, test = read_students(path)
    features, y = train[:, 1:2], train[:, 3]
    n = length(y)

    # Scale each feature to mean 0 and (sample) standard deviation 1, using
    # the training rows only. The column of ones multiplies the intercept.
    means = sum(features, dims = 1) / n
    sds = sqrt.(sum((features .- means) .^ 2, dims = 1) / (n - 1))
    scale(f) = hcat(ones(size(f, 1)), (f .- means) ./ sds)

    X = scale(features)
    weights = zeros(3)
    for _ in 1:STEPS
        # Gradient of the average log-loss: X' (p - y) / n. X' is the transpose.
        errors = sigmoid.(X * weights) .- y
        weights -= LEARNING_RATE * (X' * errors) / n
    end

    p = sigmoid.(X * weights)
    log_loss = -sum(y .* log.(p) .+ (1 .- y) .* log.(1 .- p)) / n

    predicted = sigmoid.(scale(test[:, 1:2]) * weights) .>= 0.5
    correct = count(predicted .== (test[:, 3] .== 1))

    println("train_count $n")
    println("test_count $(size(test, 1))")
    @printf("intercept %.6f\n", weights[1])
    @printf("weight_hours %.6f\n", weights[2])
    @printf("weight_sleep %.6f\n", weights[3])
    @printf("log_loss %.6f\n", log_loss)
    println("correct $correct")
    @printf("accuracy %.6f\n", correct / size(test, 1))
end

main(ARGS[1])
