# Categorical naive Bayes with add-one (Laplace) smoothing, using only Base Julia.
#
# Learns P(label) and P(feature value | label) by counting training rows, then
# labels each test row with the label that has the highest log-probability.

using Printf

const FEATURES = ["has_link", "mentions_money", "known_sender"]

function read_rows(path)
    lines = readlines(path)
    header = split(lines[1], ",")
    # Each row becomes a Dict from column name to value.
    return [Dict(zip(header, split(line, ","))) for line in lines[2:end]]
end

function main(path)
    rows = read_rows(path)
    train = filter(row -> row["split"] == "train", rows)
    test = filter(row -> row["split"] == "test", rows)

    label_counts = Dict{String,Int}()
    value_counts = Dict{Tuple{String,String,String},Int}()  # (feature, value, label)
    for row in train
        label = row["label"]
        label_counts[label] = get(label_counts, label, 0) + 1
        for f in FEATURES
            key = (f, row[f], label)
            value_counts[key] = get(value_counts, key, 0) + 1
        end
    end
    distinct_values = Dict(f => length(unique(row[f] for row in train))
                           for f in FEATURES)

    function log_score(row, label)
        # Logs turn the product of probabilities into a sum, avoiding underflow.
        score = log(label_counts[label] / length(train))
        for f in FEATURES
            # Add-one smoothing: an unseen value never gets probability zero.
            count = get(value_counts, (f, row[f], label), 0) + 1
            score += log(count / (label_counts[label] + distinct_values[f]))
        end
        return score
    end

    # Labels are tried in alphabetical order, and argmax returns the first
    # maximum, so an exact tie goes to the first label.
    labels = sort(collect(keys(label_counts)))
    classify(row) = labels[argmax([log_score(row, label) for label in labels])]

    correct = count(row -> classify(row) == row["label"], test)

    println("train_count $(length(train))")
    println("test_count $(length(test))")
    println("correct $correct")
    @printf("accuracy %.6f\n", correct / length(test))
end

main(ARGS[1])
