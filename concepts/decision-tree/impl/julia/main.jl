# A decision tree classifier (CART with Gini impurity), using only Base Julia.
#
# Grows a tree on the training days by always making the split that leaves the
# two sides purest, then predicts rain for the test days. Prints the tree in
# preorder: each node is either a split (feature and threshold) or a leaf
# (its prediction).

using Printf

const FEATURES = ["humidity", "pressure", "wind"]
const MAX_DEPTH = 3
const MIN_SIZE = 5

# A node is either a Leaf or a Split; Julia picks the right method of
# predict and show_tree by the node's type (multiple dispatch).
abstract type Node end

struct Leaf <: Node
    label::String
end

struct Split <: Node
    feature::Int
    threshold::Float64
    left::Node
    right::Node
end

struct Day
    x::Vector{Float64}
    rain::String
end

function read_days(path)
    train, test = Day[], Day[]
    for line in Iterators.drop(eachline(path), 1)  # skip the header
        humidity, pressure, wind, rain, split_name = split(line, ",")
        day = Day(parse.(Float64, [humidity, pressure, wind]), rain)
        push!(split_name == "train" ? train : test, day)
    end
    return train, test
end

function gini(days)
    # Chance that two days drawn at random (with replacement) disagree.
    p = count(d -> d.rain == "yes", days) / length(days)
    return 1 - p^2 - (1 - p)^2
end

# An even split predicts "no".
majority(days) = count(d -> d.rain == "yes", days) > length(days) / 2 ? "yes" : "no"

function best_split(days)
    # Features in column order, thresholds from smallest to largest; only a
    # strictly lower score replaces the best, so the first of any tie wins.
    best_score, best_feature, best_threshold = Inf, 0, 0.0
    for f in eachindex(FEATURES)
        values = sort(unique(d.x[f] for d in days))
        for i in 1:length(values)-1
            threshold = (values[i] + values[i+1]) / 2
            left = filter(d -> d.x[f] <= threshold, days)
            right = filter(d -> d.x[f] > threshold, days)
            weighted = length(left) * gini(left) + length(right) * gini(right)
            score = weighted / length(days)
            if score < best_score
                best_score, best_feature, best_threshold = score, f, threshold
            end
        end
    end
    return best_score, best_feature, best_threshold
end

function grow(days, depth = 0)
    impurity = gini(days)
    if impurity == 0 || length(days) < MIN_SIZE || depth == MAX_DEPTH
        return Leaf(majority(days))
    end
    score, f, threshold = best_split(days)
    score >= impurity && return Leaf(majority(days))  # no split makes the sides purer
    left = filter(d -> d.x[f] <= threshold, days)
    right = filter(d -> d.x[f] > threshold, days)
    return Split(f, threshold, grow(left, depth + 1), grow(right, depth + 1))
end

predict(node::Leaf, x) = node.label
function predict(node::Split, x)
    return predict(x[node.feature] <= node.threshold ? node.left : node.right, x)
end

# Print the tree in preorder; k counts nodes and is returned for the caller.
function show_tree(node::Leaf, k)
    println("node_$(k)_predict $(node.label)")
    return k + 1
end

function show_tree(node::Split, k)
    println("node_$(k)_feature $(FEATURES[node.feature])")
    @printf("node_%d_threshold %.6f\n", k, node.threshold)
    return show_tree(node.right, show_tree(node.left, k + 1))
end

count_leaves(node::Leaf) = 1
count_leaves(node::Split) = count_leaves(node.left) + count_leaves(node.right)

function main(path)
    train, test = read_days(path)
    tree = grow(train)

    println("train_count $(length(train))")
    println("test_count $(length(test))")
    show_tree(tree, 1)
    println("leaves $(count_leaves(tree))")

    train_correct = count(d -> predict(tree, d.x) == d.rain, train)
    correct = count(d -> predict(tree, d.x) == d.rain, test)
    @printf("train_accuracy %.6f\n", train_correct / length(train))
    println("correct $correct")
    @printf("accuracy %.6f\n", correct / length(test))
end

main(ARGS[1])
