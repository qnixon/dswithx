# Simple linear regression by least squares, using only base R.
#
# Fits score = intercept + slope * hours. lm(score ~ hours) would do it in one
# call; the sums are written out here so the formulas stay visible.

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
x <- data$hours
y <- data$score

n <- length(x)
mean_x <- sum(x) / n
mean_y <- sum(y) / n

# Sums of squared deviations and of cross-products, with no loop:
# x - mean_x is a whole vector of deviations.
sxx <- sum((x - mean_x)^2)
syy <- sum((y - mean_y)^2)
sxy <- sum((x - mean_x) * (y - mean_y))

slope <- sxy / sxx
intercept <- mean_y - slope * mean_x
r <- sxy / sqrt(sxx * syy)

results <- c(slope = slope, intercept = intercept, r = r, r_squared = r * r)

cat(sprintf("count %d\n", n))
cat(sprintf("%s %.6f\n", names(results), results), sep = "")
