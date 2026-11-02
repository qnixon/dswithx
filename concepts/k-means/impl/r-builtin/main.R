# k-means clustering with kmeans(), R's built-in function.
#
# The built-in version of ../r/main.R. kmeans() defaults to the Hartigan-Wong
# algorithm and to random starting centroids, so we ask for Lloyd's algorithm
# and pass the first k points as the centers, to match the from-scratch steps.

k <- 3

args <- commandArgs(trailingOnly = TRUE)
points <- as.matrix(read.csv(args[1])[, c("x", "y")])

fit <- kmeans(points, centers = points[1:k, ], algorithm = "Lloyd", iter.max = 100)

# fit$iter counts the assignment passes, including the last one that changed
# nothing, and tot.withinss is the inertia.
cat(sprintf("iterations %d\n", fit$iter))
for (j in 1:k) {
  cat(sprintf("centroid_%d_x %.6f\n", j, fit$centers[j, 1]))
  cat(sprintf("centroid_%d_y %.6f\n", j, fit$centers[j, 2]))
}
cat(sprintf("size_%d %d\n", 1:k, fit$size), sep = "")
cat(sprintf("inertia %.6f\n", fit$tot.withinss))
