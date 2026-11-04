# Evaluation metrics for a binary classifier, using only Elixir's standard
# library.
#
# Reads each part's true label and the model's score, then reports the
# confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
# the accuracy of never flagging anything, and the area under the ROC curve.

defmodule EvaluationMetrics do
  # Every part as {defective, score}, with each column found by its header
  # name. String.to_float needs a decimal point, which every score has.
  def read_parts(path) do
    [header | rows] =
      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.split(&1, ","))

    for fields <- rows do
      row = header |> Enum.zip(fields) |> Map.new()
      {row["defective"] == "1", String.to_float(row["score"])}
    end
  end

  # / always returns a float in Elixir, even for 6 / 3.
  def format(x), do: :erlang.float_to_binary(x, decimals: 6)

  def report(parts, suffix, threshold) do
    # A part is flagged when its score reaches the threshold. frequencies
    # counts each {flagged, defective} pair; a missing pair counts as 0.
    counts =
      Enum.frequencies(for {defective, score} <- parts, do: {score >= threshold, defective})

    tp = Map.get(counts, {true, true}, 0)
    fp = Map.get(counts, {true, false}, 0)
    # fn starts an anonymous function in Elixir, so it can't be a name.
    fn_ = Map.get(counts, {false, true}, 0)
    tn = Map.get(counts, {false, false}, 0)

    accuracy = (tp + tn) / length(parts)
    # Of the flagged parts, how many are defective.
    precision = tp / (tp + fp)
    # Of the defective parts, how many are flagged.
    recall = tp / (tp + fn_)
    f1 = 2 * precision * recall / (precision + recall)

    IO.puts("tp_at_#{suffix} #{tp}")
    IO.puts("fp_at_#{suffix} #{fp}")
    IO.puts("fn_at_#{suffix} #{fn_}")
    IO.puts("tn_at_#{suffix} #{tn}")
    IO.puts("accuracy_at_#{suffix} #{format(accuracy)}")
    IO.puts("precision_at_#{suffix} #{format(precision)}")
    IO.puts("recall_at_#{suffix} #{format(recall)}")
    IO.puts("f1_at_#{suffix} #{format(f1)}")
  end

  # The chance that a random defective part outscores a random good one.
  # Compare every pair, scoring 2 for a win and 1 for a tie, so the count
  # stays a whole number until the final division.
  def auc(parts) do
    defective = for {true, score} <- parts, do: score
    good = for {false, score} <- parts, do: score

    points =
      Enum.sum(
        for d <- defective, g <- good do
          cond do
            d > g -> 2
            d == g -> 1
            true -> 0
          end
        end
      )

    points / (2 * length(defective) * length(good))
  end
end

[path] = System.argv()
parts = EvaluationMetrics.read_parts(path)
n = length(parts)
defective = Enum.count(parts, fn {defective, _score} -> defective end)

IO.puts("parts #{n}")
IO.puts("defective #{defective}")
# Never flagging anything is right about every good part.
IO.puts("baseline_accuracy #{EvaluationMetrics.format((n - defective) / n)}")
EvaluationMetrics.report(parts, "50", 0.5)
EvaluationMetrics.report(parts, "30", 0.3)
IO.puts("auc #{EvaluationMetrics.format(EvaluationMetrics.auc(parts))}")
