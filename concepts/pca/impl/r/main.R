# Principal component analysis by power iteration, using only base R.
#
# Standardizes the four scores, builds their correlation matrix, and finds the
# top two eigenvectors (the principal components). prcomp() or eigen(cor(x))
# would do it in one call; here power iteration finds the first component,
# then deflation removes it from the matrix so the same steps find the second.

subjects <- c("math", "physics", "reading", "writing")
steps <- 1000

args <- commandArgs(trailingOnly = TRUE)
x <- unname(as.matrix(read.csv(args[1])[subjects]))
n <- nrow(x)
k <- ncol(x)

# Standardize each column to mean 0 and sample standard deviation 1 (divide
# by n - 1), written out instead of scale() and sd(). sweep() applies the
# operation column by column (margin 2).
means <- colSums(x) / n
centered <- sweep(x, 2, means)
sds <- sqrt(colSums(centered^2) / (n - 1))
z <- sweep(centered, 2, sds, "/")

# The correlation matrix, instead of cor(): t(z) %*% z sums z_i * z_j over
# the students for every pair of columns at once.
corr <- t(z) %*% z / (n - 1)

top_eigenvector <- function(m) {
  # Power iteration: multiply by the matrix and rescale, steps times.
  v <- c(1, rep(0, nrow(m) - 1))
  for (step in seq_len(steps)) {
    v <- drop(m %*% v)
    v <- v / sqrt(sum(v^2))
  }
  # An eigenvector can point either way; make its first entry positive.
  if (v[1] < 0) v <- -v
  # The Rayleigh quotient v . (M v) is the eigenvalue.
  list(value = sum(v * (m %*% v)), vector = v)
}

pc1 <- top_eigenvector(corr)
# Deflation: subtract the first component's share, leaving the rest.
# outer(v, v) is the k-by-k matrix of v_i * v_j.
deflated <- corr - pc1$value * outer(pc1$vector, pc1$vector)
pc2 <- top_eigenvector(deflated)

cat(sprintf("count %d\n", n))
for (c in 1:2) {
  pc <- list(pc1, pc2)[[c]]
  cat(sprintf("eigenvalue_%d %.6f\n", c, pc$value))
  # Standardized columns each have variance 1, so the total is k.
  cat(sprintf("explained_%d %.6f\n", c, pc$value / k))
  cat(sprintf("pc%d_%s %.6f\n", c, subjects, pc$vector), sep = "")
}
cat(sprintf("student_1_pc1 %.6f\n", sum(z[1, ] * pc1$vector)))
cat(sprintf("student_1_pc2 %.6f\n", sum(z[1, ] * pc2$vector)))
