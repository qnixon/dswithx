# 5-fold cross-validation for k-nearest neighbors, using only Elixir's
# standard library.
#
# Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
# holding out one fold at a time, picks the k with the best average
# accuracy, and then scores that k once on the untouched test seeds.

defmodule CrossValidation do
  @folds 5
  # Odd k only, so two varieties can't tie. 1..15//2 is a range with step 2.
  @ks 1..15//2

  def ks, do: @ks

  # Every row as a map, keyed by the header's column names.
  def read_rows(path) do
    [header | rows] =
      path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.split(&1, ","))

    Enum.map(rows, fn fields -> header |> Enum.zip(fields) |> Map.new() end)
  end

  # A seed is {{length, width}, variety}.
  def seed(row) do
    {length, ""} = Float.parse(row["length_mm"])
    {width, ""} = Float.parse(row["width_mm"])
    {{length, width}, row["variety"]}
  end

  def distance({l1, w1}, {l2, w2}), do: :math.sqrt((l1 - l2) ** 2 + (w1 - w2) ** 2)

  # Sort the training seeds by distance and keep the first k. Enum.sort_by
  # is a stable merge sort, so seeds at exactly equal distances stay in
  # file order.
  def nearest(train, point, k) do
    train
    |> Enum.sort_by(fn {features, _} -> distance(point, features) end)
    |> Enum.take(k)
  end

  # Enum.frequencies counts the votes into a map, but a map doesn't keep
  # first-seen order, so we walk the varieties in the order they appear.
  # max_by returns the first of equal maxima, so on a tied vote the variety
  # seen first among the neighbors wins.
  def majority(labels) do
    votes = Enum.frequencies(labels)
    labels |> Enum.uniq() |> Enum.max_by(&votes[&1])
  end

  def classify(train, point, k) do
    train |> nearest(point, k) |> Enum.map(&elem(&1, 1)) |> majority()
  end

  def count_correct(points, train, k) do
    Enum.count(points, fn {point, variety} -> classify(train, point, k) == variety end)
  end

  # Fold f is rows f*size up to (f+1)*size. The rows are already shuffled,
  # so consecutive blocks make fair folds. Enum.chunk_every cuts the list
  # into blocks of size rows; the rest is every other block, joined.
  def cv_accuracy(train, k) do
    size = div(length(train), @folds)
    blocks = Enum.chunk_every(train, size)

    correct =
      for f <- 0..(@folds - 1) do
        held_out = Enum.at(blocks, f)
        rest = blocks |> List.delete_at(f) |> Enum.concat()
        count_correct(held_out, rest, k)
      end

    Enum.sum(correct) / length(train)
  end
end

[path] = System.argv()

# split_with returns {rows that pass the test, the rest}.
{train, test} =
  path
  |> CrossValidation.read_rows()
  |> Enum.split_with(&(&1["split"] == "train"))

train = Enum.map(train, &CrossValidation.seed/1)
test = Enum.map(test, &CrossValidation.seed/1)
format = &:erlang.float_to_binary(&1, decimals: 6)

IO.puts("train_count #{length(train)}")
IO.puts("test_count #{length(test)}")

# A strictly better accuracy replaces the leader, so ties keep the smaller k.
{best_k, _} =
  Enum.reduce(CrossValidation.ks(), {nil, -1.0}, fn k, {best_k, best} ->
    accuracy = CrossValidation.cv_accuracy(train, k)
    IO.puts("cv_accuracy_k#{k} #{format.(accuracy)}")
    if accuracy > best, do: {k, accuracy}, else: {best_k, best}
  end)

# Only now touch the test seeds, once, with the chosen k and all of train.
correct = CrossValidation.count_correct(test, train, best_k)
IO.puts("best_k #{best_k}")
IO.puts("test_correct #{correct}")
IO.puts("test_accuracy #{format.(correct / length(test))}")
