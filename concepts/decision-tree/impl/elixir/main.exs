# A decision tree classifier (CART with Gini impurity), using only Elixir's
# standard library.
#
# Grows a tree on the training days by always making the split that leaves
# the two sides purest, then predicts rain for the test days. Prints the tree
# in preorder: each node is either a split (feature and threshold) or a leaf
# (its prediction).
#
# A tree is a tagged tuple: {:leaf, label} or
# {:split, feature, threshold, left, right}. Atoms such as :leaf are named
# constants, and each function below has one clause per shape.

defmodule Tree do
  @features ["humidity", "pressure", "wind"]
  @max_depth 3
  @min_size 5

  def features, do: @features

  # Each day is {values, label}, with values in the order of @features.
  # Returns {train, test}.
  def read(path) do
    [header | rows] = path |> File.read!() |> String.split("\n", trim: true)
    names = String.split(header, ",")
    col = fn name -> Enum.find_index(names, &(&1 == name)) end

    rows
    |> Enum.map(fn row ->
      fields = String.split(row, ",")
      # Float.parse returns {number, rest}; "54" parses as 54.0 too.
      values =
        Enum.map(@features, fn name ->
          {value, ""} = fields |> Enum.at(col.(name)) |> Float.parse()
          value
        end)

      {Enum.at(fields, col.("split")), {values, Enum.at(fields, col.("rain"))}}
    end)
    # split_with keeps the rows that pass in the first list, the rest in the
    # second, so this is {train, test}.
    |> Enum.split_with(fn {split, _day} -> split == "train" end)
    |> then(fn {train, test} -> {Enum.map(train, &elem(&1, 1)), Enum.map(test, &elem(&1, 1))} end)
  end

  defp count_yes(days), do: Enum.count(days, fn {_, label} -> label == "yes" end)

  # Chance that two days drawn at random (with replacement) disagree.
  defp gini(days) do
    p = count_yes(days) / length(days)
    1 - p * p - (1 - p) * (1 - p)
  end

  # Strictly more than half must be rainy, so an even split predicts "no".
  defp majority(days), do: if(2 * count_yes(days) > length(days), do: "yes", else: "no")

  # The days at or below the threshold, then the days above it.
  defp divide(days, f, threshold),
    do: Enum.split_with(days, fn {x, _} -> Enum.at(x, f) <= threshold end)

  # The weighted Gini impurity left after this split.
  defp score(days, f, threshold) do
    {left, right} = divide(days, f, threshold)
    (length(left) * gini(left) + length(right) * gini(right)) / length(days)
  end

  # Every candidate: features in column order and, for each, the midpoints
  # between neighboring distinct values, from smallest to largest.
  # chunk_every(2, 1, :discard) gives each neighboring pair [a, b].
  # The for comprehension loops over both generators, like nested loops.
  defp candidates(days) do
    for f <- 0..(length(@features) - 1), [a, b] <- neighbors(days, f), do: {f, (a + b) / 2}
  end

  defp neighbors(days, f) do
    days
    |> Enum.map(fn {x, _} -> Enum.at(x, f) end)
    |> Enum.sort()
    |> Enum.dedup()
    |> Enum.chunk_every(2, 1, :discard)
  end

  # {score, feature, threshold} with the lowest score, or nil when every
  # feature has a single value. min_by keeps the first of equal scores, so
  # the first split tried wins ties.
  defp best_split(days) do
    days
    |> candidates()
    |> Enum.map(fn {f, t} -> {score(days, f, t), f, t} end)
    |> Enum.min_by(&elem(&1, 0), fn -> nil end)
  end

  # A node becomes a leaf when it is pure, has fewer than @min_size days,
  # reaches @max_depth, or no split makes the sides purer. == compares
  # numbers by value, so 0.0 == 0 is true.
  def grow(days, depth \\ 0) do
    impurity = gini(days)

    if impurity == 0 or length(days) < @min_size or depth == @max_depth do
      {:leaf, majority(days)}
    else
      case best_split(days) do
        {s, f, t} when s < impurity ->
          {left, right} = divide(days, f, t)
          {:split, f, t, grow(left, depth + 1), grow(right, depth + 1)}

        _ ->
          {:leaf, majority(days)}
      end
    end
  end

  # Follow the splits down to a leaf.
  def predict({:leaf, label}, _x), do: label

  def predict({:split, f, t, left, right}, x),
    do: predict(if(Enum.at(x, f) <= t, do: left, else: right), x)

  # Every node in preorder: the node itself, then its left side, then its
  # right. ++ joins two lists.
  def preorder({:leaf, _} = node), do: [node]
  def preorder({:split, _, _, left, right} = node), do: [node | preorder(left) ++ preorder(right)]

  def correct(tree, days), do: Enum.count(days, fn {x, label} -> predict(tree, x) == label end)
end

six = fn value -> :erlang.float_to_binary(value, decimals: 6) end

[path] = System.argv()
{train, test} = Tree.read(path)
tree = Tree.grow(train)
nodes = Tree.preorder(tree)

IO.puts("train_count #{length(train)}")
IO.puts("test_count #{length(test)}")

# with_index numbers the nodes, here from 1.
nodes
|> Enum.with_index(1)
|> Enum.each(fn
  {{:leaf, label}, k} ->
    IO.puts("node_#{k}_predict #{label}")

  {{:split, f, t, _, _}, k} ->
    IO.puts("node_#{k}_feature #{Enum.at(Tree.features(), f)}")
    IO.puts("node_#{k}_threshold #{six.(t)}")
end)

IO.puts("leaves #{Enum.count(nodes, &match?({:leaf, _}, &1))}")
correct = Tree.correct(tree, test)
IO.puts("train_accuracy #{six.(Tree.correct(tree, train) / length(train))}")
IO.puts("correct #{correct}")
IO.puts("accuracy #{six.(correct / length(test))}")
