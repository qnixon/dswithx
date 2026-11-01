# A decision tree classifier (CART with Gini impurity), using only the standard
# library. Grows a tree on the training days by always making the split that
# leaves the two sides purest, then predicts rain for the test days. Prints the
# tree in preorder: each node is either a split (feature and threshold) or a
# leaf (its prediction).

FEATURES = %w[humidity pressure wind].freeze
MAX_DEPTH = 3
MIN_SIZE = 5

# Data.define makes a small immutable class with named fields, so the two kinds
# of node are two types, and pattern matching can tell them apart.
Leaf = Data.define(:label)
Split = Data.define(:feature, :threshold, :left, :right)

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand
# (no quoted fields here) and turn each row into a hash keyed by header name.
def read_rows(path)
  header, *lines = File.readlines(path, chomp: true)
  names = header.split(",")
  lines.map { |line| names.zip(line.split(",")).to_h }
end

# Chance that two days drawn at random (with replacement) disagree.
def gini(labels)
  p = labels.count("yes").fdiv(labels.length)
  1 - p * p - (1 - p) * (1 - p)
end

# An even split predicts "no".
def majority(labels)
  labels.count("yes") > labels.length / 2.0 ? "yes" : "no"
end

# The [score, feature, threshold] with the lowest weighted Gini impurity.
# Features are tried in column order and thresholds from smallest to largest;
# only a strictly lower score replaces the best so far.
def best_split(days)
  best = nil
  FEATURES.each_index do |f|
    days.map { |x, _| x[f] }.uniq.sort.each_cons(2) do |a, b|
      threshold = (a + b) / 2
      left, right = days.partition { |x, _| x[f] <= threshold }
      score = (left.length * gini(left.map(&:last)) +
               right.length * gini(right.map(&:last))) / days.length
      best = [score, f, threshold] if best.nil? || score < best[0]
    end
  end
  best
end

def grow(days, depth = 0)
  labels = days.map(&:last)
  if gini(labels).zero? || days.length < MIN_SIZE || depth == MAX_DEPTH
    return Leaf.new(majority(labels))
  end

  score, f, threshold = best_split(days)
  return Leaf.new(majority(labels)) if score.nil? || score >= gini(labels) # no purer split

  left, right = days.partition { |x, _| x[f] <= threshold }
  Split.new(f, threshold, grow(left, depth + 1), grow(right, depth + 1))
end

def predict(node, x)
  # case/in matches on the node's class and pulls out its fields.
  case node
  in Leaf(label) then label
  in Split(feature:, threshold:, left:, right:)
    predict(x[feature] <= threshold ? left : right, x)
  end
end

# Every node, parents before children, left subtree before right.
def preorder(node)
  return [node] if node in Leaf

  [node, *preorder(node.left), *preorder(node.right)]
end

rows = read_rows(ARGV[0])
days = rows.map { |row| [FEATURES.map { |f| Float(row[f]) }, row["rain"], row["split"]] }
train, test = days.partition { |_, _, split| split == "train" }
train = train.map { |x, label, _| [x, label] }
test = test.map { |x, label, _| [x, label] }
tree = grow(train)

puts "train_count #{train.length}"
puts "test_count #{test.length}"
nodes = preorder(tree)
nodes.each.with_index(1) do |node, k|
  case node
  in Leaf(label)
    puts "node_#{k}_predict #{label}"
  in Split(feature:, threshold:)
    puts "node_#{k}_feature #{FEATURES[feature]}"
    puts format("node_%d_threshold %.6f", k, threshold)
  end
end
puts "leaves #{nodes.count { |node| node in Leaf }}"

train_correct = train.count { |x, label| predict(tree, x) == label }
correct = test.count { |x, label| predict(tree, x) == label }
puts format("train_accuracy %.6f", train_correct.fdiv(train.length))
puts "correct #{correct}"
puts format("accuracy %.6f", correct.fdiv(test.length))
