# Categorical naive Bayes with add-one (Laplace) smoothing, using only
# Elixir's standard library.
#
# Learns P(label) and P(feature value | label) by counting training rows,
# then labels each test row with the label that has the highest
# log-probability. Enum.frequencies does the counting: it turns a list into
# a map from each distinct item to how often it appears.

defmodule NaiveBayes do
  @features ["has_link", "mentions_money", "known_sender"]

  # Every data line as a map from column name to value, such as
  # %{"label" => "spam", ...}.
  def read_rows(path) do
    [header | rows] = path |> File.read!() |> String.split("\n", trim: true)
    names = String.split(header, ",")
    Enum.map(rows, fn row -> Map.new(Enum.zip(names, String.split(row, ","))) end)
  end

  def train(rows) do
    # label -> rows
    label_counts = Enum.frequencies_by(rows, & &1["label"])
    # {feature, value, label} -> rows. Tuples compare by value, so they work
    # as map keys.
    value_counts =
      Enum.frequencies(for row <- rows, f <- @features, do: {f, row[f], row["label"]})
    # feature -> how many distinct values it takes in training
    distinct =
      Map.new(@features, fn f -> {f, rows |> Enum.uniq_by(& &1[f]) |> length()} end)

    %{n: length(rows), labels: label_counts, values: value_counts, distinct: distinct}
  end

  # Logs turn the product of probabilities into a sum, avoiding underflow.
  # Add-one smoothing means an unseen value never gets probability zero.
  def log_score(model, row, label) do
    n_label = model.labels[label]

    Enum.reduce(@features, :math.log(n_label / model.n), fn f, score ->
      # Map.get with a default of 0 covers a combination never seen.
      count = Map.get(model.values, {f, row[f], label}, 0) + 1
      score + :math.log(count / (n_label + model.distinct[f]))
    end)
  end

  # Labels are tried in alphabetical order, and Enum.max_by keeps the first
  # of equal scores, so an exact tie goes to the first.
  def classify(model, row) do
    model.labels
    |> Map.keys()
    |> Enum.sort()
    |> Enum.max_by(&log_score(model, row, &1))
  end
end

[path] = System.argv()
rows = NaiveBayes.read_rows(path)
train = Enum.filter(rows, &(&1["split"] == "train"))
test = Enum.filter(rows, &(&1["split"] == "test"))

model = NaiveBayes.train(train)
correct = Enum.count(test, &(NaiveBayes.classify(model, &1) == &1["label"]))

IO.puts("train_count #{length(train)}")
IO.puts("test_count #{length(test)}")
IO.puts("correct #{correct}")
IO.puts("accuracy #{:erlang.float_to_binary(correct / length(test), decimals: 6)}")
