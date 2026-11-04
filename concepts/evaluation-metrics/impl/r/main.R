# Evaluation metrics for a binary classifier, using only base R.
#
# Reads each part's true label and the model's score, then reports the
# confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
# the accuracy of never flagging anything, and the area under the ROC curve.

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
defective <- data$defective == 1
score <- data$score
n <- length(score)

report <- function(suffix, threshold) {
  # A part is flagged when its score reaches the threshold. Each count is
  # the sum of a logical vector, since TRUE counts as 1.
  flagged <- score >= threshold
  tp <- sum(flagged & defective)
  fp <- sum(flagged & !defective)
  fn <- sum(!flagged & defective)
  tn <- sum(!flagged & !defective)

  accuracy <- (tp + tn) / n
  precision <- tp / (tp + fp)  # of the flagged parts, how many are defective
  recall <- tp / (tp + fn)     # of the defective parts, how many are flagged
  f1 <- 2 * precision * recall / (precision + recall)

  cat(sprintf("tp_at_%s %d\n", suffix, tp))
  cat(sprintf("fp_at_%s %d\n", suffix, fp))
  cat(sprintf("fn_at_%s %d\n", suffix, fn))
  cat(sprintf("tn_at_%s %d\n", suffix, tn))
  cat(sprintf("accuracy_at_%s %.6f\n", suffix, accuracy))
  cat(sprintf("precision_at_%s %.6f\n", suffix, precision))
  cat(sprintf("recall_at_%s %.6f\n", suffix, recall))
  cat(sprintf("f1_at_%s %.6f\n", suffix, f1))
}

# The chance that a random defective part outscores a random good one.
# outer() builds the full table of defective-versus-good comparisons, one
# row per defective part. A win scores 2 and a tie 1, so the count stays a
# whole number until the final division.
auc <- function() {
  bad <- score[defective]
  good <- score[!defective]
  points <- sum(2 * outer(bad, good, ">") + outer(bad, good, "=="))
  points / (2 * length(bad) * length(good))
}

cat(sprintf("parts %d\n", n))
cat(sprintf("defective %d\n", sum(defective)))
# Never flagging anything is right about every good part.
cat(sprintf("baseline_accuracy %.6f\n", (n - sum(defective)) / n))
report("50", 0.5)
report("30", 0.3)
cat(sprintf("auc %.6f\n", auc()))
