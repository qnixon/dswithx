# k-nearest neighbors classification, using only Elixir's standard library.
#
# Each test seed is labelled with the majority variety among its k nearest
# training seeds, by Euclidean distance.

defmodule Knn do
  @k 5

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
  def nearest(train, point) do
    train
    |> Enum.sort_by(fn {features, _} -> distance(point, features) end)
    |> Enum.take(@k)
  end

  # Enum.frequencies counts the votes into a map, but a map doesn't keep
  # first-seen order, so we walk the varieties in the order they appear.
  # max_by returns the first of equal maxima, so on a tied vote the variety
  # seen first among the neighbors wins.
  def majority(labels) do
    votes = Enum.frequencies(labels)
    labels |> Enum.uniq() |> Enum.max_by(&votes[&1])
  end

  def classify(train, point) do
    train |> nearest(point) |> Enum.map(&elem(&1, 1)) |> majority()
  end
end

[path] = System.argv()

# split_with returns {rows that pass the test, the rest}.
{train, test} =
  path
  |> Knn.read_rows()
  |> Enum.split_with(&(&1["split"] == "train"))

train = Enum.map(train, &Knn.seed/1)
test = Enum.map(test, &Knn.seed/1)
correct = Enum.count(test, fn {point, variety} -> Knn.classify(train, point) == variety end)

IO.puts("train_count #{length(train)}")
IO.puts("test_count #{length(test)}")
IO.puts("correct #{correct}")
IO.puts("accuracy #{:erlang.float_to_binary(correct / length(test), decimals: 6)}")
