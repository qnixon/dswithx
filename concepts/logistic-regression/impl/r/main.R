# Logistic regression by gradient descent, using only base R.
#
# Predicts whether a student passed from study hours and sleep.
# glm(passed ~ hours + sleep, family = binomial) would fit it in one call (by
# a different method, iteratively reweighted least squares); here the weights
# start at zero and take a fixed number of batch gradient-descent steps.

learning_rate <- 0.5
steps <- 1000

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
train <- data[data$split == "train", ]
test <- data[data$split == "test", ]
features <- c("hours", "sleep")

# Training means and sample standard deviations (divide by n - 1), written out
# instead of mean() and sd(). sapply runs the function once per column.
means <- sapply(train[features], function(v) sum(v) / length(v))
sds <- sapply(features, function(f) {
  v <- train[[f]]
  sqrt(sum((v - means[f])^2) / (length(v) - 1))
})

# A matrix with a column of 1s for the intercept, then the scaled features.
# sweep() subtracts each column's mean, then divides by its sd. unname()
# drops the column names, which would otherwise ride along into the weights.
design <- function(rows) {
  x <- as.matrix(rows[features])
  unname(cbind(1, sweep(sweep(x, 2, means), 2, sds, "/")))
}

sigmoid <- function(z) 1 / (1 + exp(-z))

x <- design(train)
y <- train$passed
n <- nrow(x)

w <- rep(0, ncol(x))
for (step in seq_len(steps)) {
  # x %*% w is every row's w . x at once; t(x) %*% errors sums error times
  # input for each weight, so dividing by n gives the gradient.
  errors <- sigmoid(drop(x %*% w)) - y
  gradient <- drop(t(x) %*% errors) / n
  w <- w - learning_rate * gradient
}

p <- sigmoid(drop(x %*% w))
log_loss <- -sum(y * log(p) + (1 - y) * log(1 - p)) / n

predicted <- ifelse(sigmoid(drop(design(test) %*% w)) >= 0.5, 1, 0)
correct <- sum(predicted == test$passed)

results <- c(intercept = w[1], weight_hours = w[2], weight_sleep = w[3], log_loss = log_loss)

cat(sprintf("train_count %d\n", n))
cat(sprintf("test_count %d\n", nrow(test)))
cat(sprintf("%s %.6f\n", names(results), results), sep = "")
cat(sprintf("correct %d\n", correct))
cat(sprintf("accuracy %.6f\n", correct / nrow(test)))
