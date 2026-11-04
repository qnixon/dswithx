# 5-fold cross-validation for k-nearest neighbors, using only base R.
#
# Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
# holding out one fold at a time, picks the k with the best average accuracy,
# and then scores that k once on the untouched test seeds.

folds <- 5
ks <- seq(1, 15, by = 2)  # odd k only, so two varieties can't tie

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
train <- data[data$split == "train", ]
test <- data[data$split == "test", ]

classify <- function(length_mm, width_mm, seeds, k) {
  # Distances from this point to every seed at once. order() is stable, so
  # equal distances keep file order.
  distance <- sqrt((seeds$length_mm - length_mm)^2 + (seeds$width_mm - width_mm)^2)
  nearest <- seeds$variety[order(distance)[1:k]]
  # table() counts the votes; with two varieties and odd k there is no tie.
  votes <- table(nearest)
  names(votes)[which.max(votes)]
}

count_correct <- function(points, seeds, k) {
  # MoreArgs passes the same seeds and k to every call.
  predicted <- mapply(classify, points$length_mm, points$width_mm,
                      MoreArgs = list(seeds = seeds, k = k))
  sum(predicted == points$variety)
}

cv_accuracy <- function(k) {
  # Fold f is rows (f - 1) * size + 1 to f * size. The rows are already
  # shuffled, so consecutive blocks make fair folds.
  size <- nrow(train) %/% folds
  correct <- 0
  for (f in 1:folds) {
    rows <- ((f - 1) * size + 1):(f * size)
    # A negative index drops those rows, leaving the other four folds.
    correct <- correct + count_correct(train[rows, ], train[-rows, ], k)
  }
  correct / nrow(train)
}

cat(sprintf("train_count %d\n", nrow(train)))
cat(sprintf("test_count %d\n", nrow(test)))
best_k <- NA
best_accuracy <- -1
for (k in ks) {
  accuracy <- cv_accuracy(k)
  cat(sprintf("cv_accuracy_k%d %.6f\n", k, accuracy))
  if (accuracy > best_accuracy) {  # strictly better, so ties keep the smaller k
    best_k <- k
    best_accuracy <- accuracy
  }
}

# Only now touch the test seeds, once, with the chosen k and all of train.
correct <- count_correct(test, train, best_k)
cat(sprintf("best_k %d\n", best_k))
cat(sprintf("test_correct %d\n", correct))
cat(sprintf("test_accuracy %.6f\n", correct / nrow(test)))
