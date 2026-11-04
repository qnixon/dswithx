# Exact two-sided permutation test for a difference in means, using only
# base R.
#
# If compost made no difference, the "compost" and "control" labels are
# arbitrary, and any 8 of the 16 plants could have carried the compost label.
# We try every one of those splits and count how many give a difference at
# least as large as the one we observed. That fraction is the p-value.

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
control <- data$grams[data$group == "control"]
compost <- data$grams[data$group == "compost"]
n <- length(compost)
plants <- c(control, compost)
total <- sum(plants)

# Both groups have n plants, so comparing totals is the same as comparing
# means, and totals stay whole numbers: no floating-point near-ties.
observed <- sum(compost) - sum(control)

# combn() lists every choice of n plants, one per column. With FUN = sum it
# returns each choice's total instead, so we get all splits in one vector.
relabeled <- combn(plants, n, FUN = sum)
difference <- relabeled - (total - relabeled)
splits <- length(difference)
as_extreme <- sum(abs(difference) >= abs(observed))  # two-sided

cat(sprintf("control_count %d\n", length(control)))
cat(sprintf("compost_count %d\n", n))
cat(sprintf("control_mean %.6f\n", mean(control)))
cat(sprintf("compost_mean %.6f\n", mean(compost)))
cat(sprintf("observed_difference %.6f\n", observed / n))
cat(sprintf("splits %d\n", splits))
cat(sprintf("as_extreme %d\n", as_extreme))
cat(sprintf("p_value %.6f\n", as_extreme / splits))
