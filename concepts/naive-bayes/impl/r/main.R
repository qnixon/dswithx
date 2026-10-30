# Categorical naive Bayes with add-one (Laplace) smoothing, using only base R.
#
# Learns P(label) and P(feature value | label) by counting training rows, then
# labels each test row with the label that has the highest log-probability.

features <- c("has_link", "mentions_money", "known_sender")

args <- commandArgs(trailingOnly = TRUE)
# colClasses keeps "yes"/"no" as plain strings.
data <- read.csv(args[1], colClasses = "character")
train <- data[data$split == "train", ]
test <- data[data$split == "test", ]

# table() sorts its names, so labels come out in alphabetical order.
label_counts <- table(train$label)
labels <- names(label_counts)

log_score <- function(row, label) {
  in_label <- train[train$label == label, ]
  # Logs turn the product of probabilities into a sum, avoiding underflow.
  score <- log(label_counts[[label]] / nrow(train))
  for (f in features) {
    # Add-one smoothing: an unseen value never gets probability zero.
    # m is the number of distinct values the feature takes in training.
    count <- sum(in_label[[f]] == row[[f]]) + 1
    m <- length(unique(train[[f]]))
    score <- score + log(count / (label_counts[[label]] + m))
  }
  score
}

classify <- function(row) {
  scores <- sapply(labels, function(label) log_score(row, label))
  labels[which.max(scores)]  # first maximum, so a tie goes to the first label
}

predicted <- sapply(seq_len(nrow(test)), function(i) classify(test[i, ]))
correct <- sum(predicted == test$label)

cat(sprintf("train_count %d\n", nrow(train)))
cat(sprintf("test_count %d\n", nrow(test)))
cat(sprintf("correct %d\n", correct))
cat(sprintf("accuracy %.6f\n", correct / nrow(test)))
