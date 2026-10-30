# Descriptive statistics on one CSV column, using only base R.
#
# R has mean(), median(), var(), and sd() built in; they are avoided here so
# the arithmetic stays visible.

column <- "minutes"

args <- commandArgs(trailingOnly = TRUE)
values <- sort(read.csv(args[1])[[column]])

n <- length(values)
total <- sum(values)
mean_value <- total / n

# Vectors are 1-indexed: for n = 120 the middle pair is values[60], values[61].
middle <- n %/% 2
median_value <- if (n %% 2 == 1) values[middle + 1] else (values[middle] + values[middle + 1]) / 2

# Sample variance divides by n - 1, not n (Bessel's correction).
# values - mean_value subtracts the mean from every element at once.
variance <- sum((values - mean_value)^2) / (n - 1)

results <- c(
  sum = total,
  mean = mean_value,
  median = median_value,
  min = values[1],
  max = values[n],
  range = values[n] - values[1],
  variance = variance,
  std_dev = sqrt(variance)
)

cat(sprintf("count %d\n", n))
cat(sprintf("%s %.6f\n", names(results), results), sep = "")
