# Descriptive statistics on one CSV column, with R's built-in functions.
#
# The built-in version of ../r/main.R: mean(), median(), var(), and sd() do
# the arithmetic. var() and sd() are the sample versions, dividing by n - 1.

column <- "minutes"

args <- commandArgs(trailingOnly = TRUE)
values <- read.csv(args[1])[[column]]

results <- c(
  sum = sum(values),
  mean = mean(values),
  median = median(values),
  min = min(values),
  max = max(values),
  range = diff(range(values)),
  variance = var(values),
  std_dev = sd(values)
)

cat(sprintf("count %d\n", length(values)))
cat(sprintf("%s %.6f\n", names(results), results), sep = "")
