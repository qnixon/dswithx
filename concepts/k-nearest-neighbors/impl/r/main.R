# k-nearest neighbors classification, using only base R.
#
# Each test seed is labelled with the majority variety among its k = 5 nearest
# training seeds, by Euclidean distance.

k <- 5

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
train <- data[data$split == "train", ]
test <- data[data$split == "test", ]

classify <- function(length_mm, width_mm) {
  # Distances from this point to every training seed at once. order() is
  # stable, so equal distances keep file order.
  distance <- sqrt((train$length_mm - length_mm)^2 + (train$width_mm - width_mm)^2)
  nearest <- train$variety[order(distance)[1:k]]
  # table() counts the votes; with two varieties and odd k there is no tie.
  votes <- table(nearest)
  names(votes)[which.max(votes)]
}

predicted <- mapply(classify, test$length_mm, test$width_mm)
correct <- sum(predicted == test$variety)

cat(sprintf("train_count %d\n", nrow(train)))
cat(sprintf("test_count %d\n", nrow(test)))
cat(sprintf("correct %d\n", correct))
cat(sprintf("accuracy %.6f\n", correct / nrow(test)))
