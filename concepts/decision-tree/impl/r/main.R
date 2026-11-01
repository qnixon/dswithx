# A decision tree classifier (CART with Gini impurity), using only base R.
#
# Grows a tree on the training days by always making the split that leaves the
# two sides purest, then predicts rain for the test days. Prints the tree in
# preorder: each node is either a split (feature and threshold) or a leaf.
# rpart() would grow a tree like this in one call; it is a recommended package,
# which this image removes.

features <- c("humidity", "pressure", "wind")
max_depth <- 3
min_size <- 5

args <- commandArgs(trailingOnly = TRUE)
data <- read.csv(args[1])
data$rain <- data$rain == "yes"  # TRUE/FALSE, so sum() counts the rainy days
train <- data[data$split == "train", ]
test <- data[data$split == "test", ]

# Chance that two days drawn at random (with replacement) disagree, from the
# share p of rainy days. Works on a whole vector of shares at once.
gini <- function(p) 1 - p^2 - (1 - p)^2

# An even split predicts "no".
majority <- function(rain) if (sum(rain) > length(rain) / 2) "yes" else "no"

# The best split as list(score, feature, threshold), or NULL if there is none.
best_split <- function(days) {
  best <- NULL
  n <- nrow(days)
  for (f in features) {
    values <- sort(unique(days[[f]]))
    if (length(values) < 2) next
    thresholds <- (head(values, -1) + tail(values, -1)) / 2
    # A table with one row per day and one column per threshold: TRUE where
    # the day goes left. colSums counts each column, so every threshold's
    # left-side size and rainy count come out at once.
    goes_left <- outer(days[[f]], thresholds, "<=")
    n_left <- colSums(goes_left)
    yes_left <- colSums(goes_left * days$rain)
    n_right <- n - n_left
    yes_right <- sum(days$rain) - yes_left
    scores <- (n_left * gini(yes_left / n_left) +
               n_right * gini(yes_right / n_right)) / n
    i <- which.min(scores)  # first minimum, so the smallest threshold wins ties
    if (is.null(best) || scores[i] < best$score) {
      best <- list(score = scores[i], feature = f, threshold = thresholds[i])
    }
  }
  best
}

# A leaf is "yes" or "no"; a split is a list with feature, threshold, left,
# and right. Recursion grows each side as a smaller tree.
grow <- function(days, depth = 0) {
  node_gini <- gini(sum(days$rain) / nrow(days))
  if (node_gini == 0 || nrow(days) < min_size || depth == max_depth) {
    return(majority(days$rain))
  }
  split <- best_split(days)
  if (is.null(split) || split$score >= node_gini) {
    return(majority(days$rain))  # no split makes the sides purer
  }
  left <- days[[split$feature]] <= split$threshold
  list(feature = split$feature, threshold = split$threshold,
       left = grow(days[left, ], depth + 1),
       right = grow(days[!left, ], depth + 1))
}

predict_day <- function(node, day) {
  while (is.list(node)) {
    node <- if (day[[node$feature]] <= node$threshold) node$left else node$right
  }
  node
}

# Every node, root first, then the left subtree, then the right.
preorder <- function(node) {
  if (!is.list(node)) return(list(node))
  c(list(node), preorder(node$left), preorder(node$right))
}

tree <- grow(train)
count_correct <- function(days) {
  predicted <- sapply(seq_len(nrow(days)),
                      function(i) predict_day(tree, days[i, ]))
  sum(predicted == ifelse(days$rain, "yes", "no"))
}

cat(sprintf("train_count %d\n", nrow(train)))
cat(sprintf("test_count %d\n", nrow(test)))
nodes <- preorder(tree)
for (k in seq_along(nodes)) {
  node <- nodes[[k]]
  if (is.list(node)) {
    cat(sprintf("node_%d_feature %s\n", k, node$feature))
    cat(sprintf("node_%d_threshold %.6f\n", k, node$threshold))
  } else {
    cat(sprintf("node_%d_predict %s\n", k, node))
  }
}
cat(sprintf("leaves %d\n", sum(!sapply(nodes, is.list))))
correct <- count_correct(test)
cat(sprintf("train_accuracy %.6f\n", count_correct(train) / nrow(train)))
cat(sprintf("correct %d\n", correct))
cat(sprintf("accuracy %.6f\n", correct / nrow(test)))
