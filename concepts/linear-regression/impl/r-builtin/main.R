# Simple linear regression with lm(), R's linear-model function.
#
# The built-in version of ../r/main.R. The formula score ~ hours asks for
# score = intercept + slope * hours, and summary() reports R squared.

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])

model <- lm(score ~ hours, data = data)
coefs <- coef(model)  # named: "(Intercept)" and "hours"

results <- c(
  slope = unname(coefs["hours"]),
  intercept = unname(coefs["(Intercept)"]),
  r = cor(data$hours, data$score),
  r_squared = summary(model)$r.squared
)

cat(sprintf("count %d\n", nrow(data)))
cat(sprintf("%s %.6f\n", names(results), results), sep = "")
