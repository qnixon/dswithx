# Evaluation metrics for a binary classifier, using only the standard
# library.
#
# Reads each part's true label and the model's score, then reports the
# confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
# the accuracy of never flagging anything, and the area under the ROC curve.

THRESHOLDS = [["50", 0.5], ["30", 0.3]].freeze # name suffix, threshold

# The csv library is a bundled gem since Ruby 3.4, so split lines by hand
# (no quoted fields here). Each part becomes [defective?, score].
def read(path)
  header, *lines = File.readlines(path, chomp: true)
  columns = header.split(",")
  i_label = columns.index("defective")
  i_score = columns.index("score")
  lines.map do |line|
    fields = line.split(",")
    [fields[i_label] == "1", Float(fields[i_score])]
  end
end

def report(parts, suffix, threshold)
  # A part is flagged when its score reaches the threshold.
  tp = fp = fn = tn = 0
  parts.each do |defective, score|
    flagged = score >= threshold
    if flagged && defective then tp += 1
    elsif flagged then fp += 1
    elsif defective then fn += 1
    else tn += 1
    end
  end

  accuracy = (tp + tn).fdiv(parts.length)
  precision = tp.fdiv(tp + fp) # of the flagged parts, how many are defective
  recall = tp.fdiv(tp + fn)    # of the defective parts, how many are flagged
  f1 = 2 * precision * recall / (precision + recall)

  puts "tp_at_#{suffix} #{tp}"
  puts "fp_at_#{suffix} #{fp}"
  puts "fn_at_#{suffix} #{fn}"
  puts "tn_at_#{suffix} #{tn}"
  puts format("accuracy_at_%s %.6f", suffix, accuracy)
  puts format("precision_at_%s %.6f", suffix, precision)
  puts format("recall_at_%s %.6f", suffix, recall)
  puts format("f1_at_%s %.6f", suffix, f1)
end

# The chance that a random defective part outscores a random good one.
# Compare every pair, scoring 2 for a win and 1 for a tie, so the count
# stays a whole number until the final division.
def auc(parts)
  defective, good = parts.partition(&:first).map { |group| group.map(&:last) }
  points = 0
  defective.each do |d|
    good.each do |g|
      points += 2 if d > g
      points += 1 if d == g
    end
  end
  points.fdiv(2 * defective.length * good.length)
end

parts = read(ARGV[0])
defective = parts.count(&:first)

puts "parts #{parts.length}"
puts "defective #{defective}"
# Never flagging anything is right about every good part.
puts format("baseline_accuracy %.6f", (parts.length - defective).fdiv(parts.length))
THRESHOLDS.each { |suffix, threshold| report(parts, suffix, threshold) }
puts format("auc %.6f", auc(parts))
