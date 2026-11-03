# Logistic regression with glm(), R's generalized linear model function.
#
# The built-in version of ../r/main.R. family = binomial makes glm() fit a
# logistic regression. It finds the weights by iteratively reweighted least
# squares, not gradient descent, but reaches the same answer.

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
train <- data[data$split == "train", ]
test <- data[data$split == "test", ]
features <- c("hours", "sleep")

# scale() standardizes each column with its mean and sample standard
# deviation, and remembers both, so the test rows can use the training ones.
scaled_train <- scale(train[features])
center <- attr(scaled_train, "scaled:center")
spread <- attr(scaled_train, "scaled:scale")
scaled_test <- scale(test[features], center = center, scale = spread)

model <- glm(train$passed ~ scaled_train, family = binomial)
w <- unname(coef(model))  # intercept, then hours and sleep

p <- fitted(model)  # each training student's probability of passing
y <- train$passed
log_loss <- -mean(y * log(p) + (1 - y) * log(1 - p))

# plogis() is the logistic (sigmoid) function.
predicted <- ifelse(plogis(drop(cbind(1, scaled_test) %*% w)) >= 0.5, 1, 0)
correct <- sum(predicted == test$passed)

results <- c(intercept = w[1], weight_hours = w[2], weight_sleep = w[3], log_loss = log_loss)

cat(sprintf("train_count %d\n", nrow(train)))
cat(sprintf("test_count %d\n", nrow(test)))
cat(sprintf("%s %.6f\n", names(results), results), sep = "")
cat(sprintf("correct %d\n", correct))
cat(sprintf("accuracy %.6f\n", correct / nrow(test)))
