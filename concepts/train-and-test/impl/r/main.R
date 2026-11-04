# Train and test error for polynomials of degree 1 to 8, using only base R.
#
# Each polynomial is fitted by least squares to the training drives only:
# we build the normal equations and solve them by Gaussian elimination,
# written out instead of lm() or solve(). Then we measure its root-mean-square
# error on the training drives and on the test drives it never saw.

max_degree <- 8

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
is_train <- data$split == "train"
train_x <- data$speed[is_train]
train_y <- data$litres[is_train]
test_x <- data$speed[!is_train]
test_y <- data$litres[!is_train]

# Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
# largest entry at degree 8) would swamp the small ones and make the
# equations hard to solve accurately.
low <- min(train_x)
high <- max(train_x)
mid <- (low + high) / 2
half <- (high - low) / 2
scale <- function(x) (x - mid) / half

# Solve a x = b by Gaussian elimination with partial pivoting.
gauss <- function(a, b) {
  n <- length(b)
  m <- cbind(a, b)  # augmented matrix; R copies on change, so a is untouched
  for (col in 1:n) {
    # Swap up the row with the largest entry in this column, which keeps
    # the rounding error small. which.max() finds the first largest.
    pivot <- col - 1 + which.max(abs(m[col:n, col]))
    m[c(col, pivot), ] <- m[c(pivot, col), ]
    if (col < n) {
      for (r in (col + 1):n) {
        factor <- m[r, col] / m[col, col]
        m[r, ] <- m[r, ] - factor * m[col, ]  # a whole row at once
      }
    }
  }
  # Back substitution, from the last unknown up.
  x <- numeric(n)
  for (r in n:1) {
    later <- seq_len(n - r) + r  # the columns after r (none for the last)
    x[r] <- (m[r, n + 1] - sum(m[r, later] * x[later])) / m[r, r]
  }
  x
}

# Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i
# of Z is 1, z_i, z_i^2, ..., z_i^degree. outer() builds Z, one column per
# power, and %*% is plain matrix multiplication.
fit <- function(degree) {
  z <- outer(scale(train_x), 0:degree, "^")
  gauss(t(z) %*% z, drop(t(z) %*% train_y))
}

rmse <- function(coefs, x, y) {
  z <- outer(scale(x), 0:(length(coefs) - 1), "^")
  predicted <- drop(z %*% coefs)
  sqrt(sum((predicted - y)^2) / length(y))
}

cat(sprintf("train_count %d\n", length(train_x)))
cat(sprintf("test_count %d\n", length(test_x)))
degrees <- 1:max_degree
coefs <- lapply(degrees, fit)
train_rmse <- sapply(coefs, rmse, train_x, train_y)
test_rmse <- sapply(coefs, rmse, test_x, test_y)
cat(sprintf("train_rmse_d%d %.6f\n", degrees, train_rmse), sep = "")
cat(sprintf("test_rmse_d%d %.6f\n", degrees, test_rmse), sep = "")
