# Evaluation metrics for a binary classifier, using only Base Julia.
#
# Reads each part's true label and the model's score, then reports the
# confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
# the accuracy of never flagging anything, and the area under the ROC curve.

using Printf

const THRESHOLDS = (("50", 0.5), ("30", 0.3))  # name suffix, threshold

# Each part becomes a (defective, score) tuple; columns are found by name.
function read_parts(path)
    lines = readlines(path)
    columns = split(lines[1], ",")
    i_label = findfirst(==("defective"), columns)
    i_score = findfirst(==("score"), columns)
    return [(fields[i_label] == "1", parse(Float64, fields[i_score]))
            for fields in (split(line, ",") for line in lines[2:end])]
end

function report(parts, suffix, threshold)
    # A part is flagged when its score reaches the threshold.
    tp = fp = fn = tn = 0
    for (defective, score) in parts
        flagged = score >= threshold
        if flagged && defective
            tp += 1
        elseif flagged
            fp += 1
        elseif defective
            fn += 1
        else
            tn += 1
        end
    end

    accuracy = (tp + tn) / length(parts)  # / on two Ints gives a Float64
    precision = tp / (tp + fp)  # of the flagged parts, how many are defective
    recall = tp / (tp + fn)     # of the defective parts, how many are flagged
    f1 = 2 * precision * recall / (precision + recall)

    println("tp_at_$suffix $tp")
    println("fp_at_$suffix $fp")
    println("fn_at_$suffix $fn")
    println("tn_at_$suffix $tn")
    @printf("accuracy_at_%s %.6f\n", suffix, accuracy)
    @printf("precision_at_%s %.6f\n", suffix, precision)
    @printf("recall_at_%s %.6f\n", suffix, recall)
    @printf("f1_at_%s %.6f\n", suffix, f1)
end

# The chance that a random defective part outscores a random good one.
# Compare every pair, scoring 2 for a win and 1 for a tie, so the count
# stays a whole number until the final division.
function auc(parts)
    defective = [score for (is_defective, score) in parts if is_defective]
    good = [score for (is_defective, score) in parts if !is_defective]
    points = 0
    for d in defective, g in good
        if d > g
            points += 2
        elseif d == g
            points += 1
        end
    end
    return points / (2 * length(defective) * length(good))
end

function main(path)
    parts = read_parts(path)
    defective = count(first, parts)

    println("parts $(length(parts))")
    println("defective $defective")
    # Never flagging anything is right about every good part.
    @printf("baseline_accuracy %.6f\n", (length(parts) - defective) / length(parts))
    for (suffix, threshold) in THRESHOLDS
        report(parts, suffix, threshold)
    end
    @printf("auc %.6f\n", auc(parts))
end

main(ARGS[1])
