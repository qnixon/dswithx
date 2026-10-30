# k-means clustering (Lloyd's algorithm), using only base R.
#
# Starts from the first k points as centroids, then alternates two steps until
# no point changes cluster: assign each point to its nearest centroid, and move
# each centroid to the mean of its points. kmeans() is built in; it is avoided
# here so the loop stays visible.

k <- 3
max_iterations <- 100

args <- commandArgs(trailingOnly = TRUE)
points <- as.matrix(read.csv(args[1])[, c("x", "y")])

# One centroid per row; rows 1..k of the data are the starting centroids.
centroids <- points[1:k, , drop = FALSE]

nearest <- function(point) {
  distance <- (centroids[, 1] - point[1])^2 + (centroids[, 2] - point[2])^2
  which.min(distance)  # first minimum, so ties go to the lower index
}

assignment <- NULL
iterations <- 0
while (iterations < max_iterations) {
  iterations <- iterations + 1
  new_assignment <- apply(points, 1, nearest)
  if (identical(new_assignment, assignment)) break
  assignment <- new_assignment
  for (j in 1:k) {
    members <- points[assignment == j, , drop = FALSE]
    if (nrow(members) > 0) {  # an empty cluster keeps its old centroid
      centroids[j, ] <- colSums(members) / nrow(members)
    }
  }
}

sizes <- tabulate(assignment, nbins = k)
# centroids[assignment, ] lines up each point with its own centroid.
inertia <- sum((points - centroids[assignment, , drop = FALSE])^2)

cat(sprintf("iterations %d\n", iterations))
for (j in 1:k) {
  cat(sprintf("centroid_%d_x %.6f\n", j, centroids[j, 1]))
  cat(sprintf("centroid_%d_y %.6f\n", j, centroids[j, 2]))
}
cat(sprintf("size_%d %d\n", 1:k, sizes), sep = "")
cat(sprintf("inertia %.6f\n", inertia))
