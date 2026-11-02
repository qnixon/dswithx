# Principal component analysis with prcomp(), R's built-in PCA.
#
# The built-in version of ../r/main.R. scale. = TRUE standardizes each column
# first, so the components are the eigenvectors of the correlation matrix.
# prcomp() may return any component with every sign flipped, so we apply the
# same rule as the from-scratch version: each one's first entry is positive.

subjects <- c("math", "physics", "reading", "writing")

args <- commandArgs(trailingOnly = TRUE)
x <- read.csv(args[1])[subjects]
k <- ncol(x)

pca <- prcomp(x, scale. = TRUE)
# rotation holds one component per column; sdev holds each one's standard
# deviation, so its square is the eigenvalue.
signs <- sign(pca$rotation[1, ])
rotation <- sweep(pca$rotation, 2, signs, "*")
scores <- sweep(pca$x, 2, signs, "*")  # each student's position on each component
eigenvalues <- pca$sdev^2

cat(sprintf("count %d\n", nrow(x)))
for (c in 1:2) {
  cat(sprintf("eigenvalue_%d %.6f\n", c, eigenvalues[c]))
  # Standardized columns each have variance 1, so the total is k.
  cat(sprintf("explained_%d %.6f\n", c, eigenvalues[c] / k))
  cat(sprintf("pc%d_%s %.6f\n", c, subjects, rotation[, c]), sep = "")
}
cat(sprintf("student_1_pc1 %.6f\n", scores[1, 1]))
cat(sprintf("student_1_pc2 %.6f\n", scores[1, 2]))
