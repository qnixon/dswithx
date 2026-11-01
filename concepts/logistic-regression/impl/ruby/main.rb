# Logistic regression by gradient descent, using only the standard library.
# Predicts whether a student passed from study hours and sleep. Each feature is
# rescaled with the training rows' mean and standard deviation, then the weights
# start at zero and take STEPS fixed steps of batch gradient descent on the
# average log-loss.

FEATURES = %w[hours sleep].freeze
LABEL = "passed"
LEARNING_RATE = 0.5
STEPS = 1000

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand
# (no quoted fields here) and turn each row into a hash keyed by header name.
def read_rows(path)
  header, *lines = File.readlines(path, chomp: true)
  names = header.split(",")
  lines.map { |line| names.zip(line.split(",")).to_h }
end

def sigmoid(z)
  1 / (1 + Math.exp(-z))
end

def dot(a, b)
  a.zip(b).sum { |u, v| u * v }
end

rows = read_rows(ARGV[0])
examples = rows.map { |row| [FEATURES.map { |f| Float(row[f]) }, Integer(row[LABEL]), row["split"]] }
train, test = examples.partition { |_, _, split| split == "train" }

# Scale each feature to mean 0 and (sample) standard deviation 1, using the
# training rows only. transpose turns the rows into one array per feature.
columns = train.map(&:first).transpose
means = columns.map { |c| c.sum / c.length }
sds = columns.zip(means).map { |c, m| Math.sqrt(c.sum { |v| (v - m)**2 } / (c.length - 1)) }

# The leading 1.0 multiplies the intercept.
scale = ->(x) { [1.0] + x.zip(means, sds).map { |v, m, s| (v - m) / s } }

xs = train.map { |x, _, _| scale.(x) }
ys = train.map { |_, y, _| y }
n = xs.length

weights = Array.new(xs.first.length, 0.0)
STEPS.times do
  # Gradient of the average log-loss: the mean of (p - y) times each input.
  errors = xs.zip(ys).map { |x, y| sigmoid(dot(weights, x)) - y }
  gradient = weights.each_index.map { |j| errors.zip(xs).sum { |e, x| e * x[j] } / n }
  weights = weights.zip(gradient).map { |w, g| w - LEARNING_RATE * g }
end

log_loss = -xs.zip(ys).sum do |x, y|
  p = sigmoid(dot(weights, x))
  y * Math.log(p) + (1 - y) * Math.log(1 - p)
end / n

correct = test.count { |x, y, _| (sigmoid(dot(weights, scale.(x))) >= 0.5 ? 1 : 0) == y }

puts "train_count #{n}"
puts "test_count #{test.length}"
{ intercept: weights[0], weight_hours: weights[1], weight_sleep: weights[2],
  log_loss: log_loss }.each do |name, value|
  puts format("%s %.6f", name, value)
end
puts "correct #{correct}"
puts format("accuracy %.6f", correct.to_f / test.length)
