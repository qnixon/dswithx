# Logistic regression by gradient descent, using only Elixir's standard
# library.
#
# Predicts whether a student passed from study hours and sleep. Each feature
# is rescaled with the training rows' mean and standard deviation, then the
# weights start at zero and take 1,000 steps of batch gradient descent on the
# average log-loss. Data never changes in place, so each step builds a new
# list of weights from the old one.

defmodule Logistic do
  @learning_rate 0.5                   # @name is a constant, fixed at compile time
  @steps 1000

  # Each row becomes {[hours, sleep], passed, split}.
  def read_rows(path) do
    [header | lines] = path |> File.read!() |> String.split("\n", trim: true)
    names = String.split(header, ",")
    col = fn name -> Enum.find_index(names, &(&1 == name)) || raise "column not found: #{name}" end
    [hours, sleep, passed, split] = Enum.map(~w(hours sleep passed split), col)

    Enum.map(lines, fn line ->
      f = line |> String.split(",") |> List.to_tuple()   # elem(f, i) reads field i
      {[number(elem(f, hours)), number(elem(f, sleep))], String.to_integer(elem(f, passed)), elem(f, split)}
    end)
  end

  # Float.parse returns {number, rest}; "7" parses as 7.0 too.
  defp number(text) do
    {value, ""} = Float.parse(text)
    value
  end

  def sigmoid(z), do: 1 / (1 + :math.exp(-z))

  # zip_reduce walks two lists side by side, carrying a running total.
  def dot(u, v), do: Enum.zip_reduce(u, v, 0.0, fn a, b, acc -> acc + a * b end)

  def mean(xs), do: Enum.sum(xs) / length(xs)

  # Sample standard deviation: divide by n - 1.
  def sd(xs) do
    m = mean(xs)
    :math.sqrt((xs |> Enum.map(&((&1 - m) ** 2)) |> Enum.sum()) / (length(xs) - 1))
  end

  # The columns of a list of rows: zip_with gathers the first of every row,
  # then the second, and so on.
  def columns(rows), do: Enum.zip_with(rows, & &1)

  # One step. Every error comes from the old weights before any weight moves,
  # so every weight moves from the same gradient: the mean of (p - y) times
  # its input.
  def step(xs, cols, ys, weights) do
    n = length(xs)
    errors = Enum.zip_with(xs, ys, fn x, y -> sigmoid(dot(weights, x)) - y end)
    Enum.zip_with(weights, cols, fn w, col -> w - @learning_rate * dot(errors, col) / n end)
  end

  def descend(xs, ys) do
    cols = columns(xs)
    # reduce threads the weights through 1,000 steps; _ ignores the step number.
    Enum.reduce(1..@steps, [0.0, 0.0, 0.0], fn _, weights -> step(xs, cols, ys, weights) end)
  end

  def say(name, value), do: IO.puts("#{name} #{:erlang.float_to_binary(value, decimals: 6)}")
end

[path] = System.argv()
# split_with divides the rows into those that pass the test and the rest.
{train, test} = path |> Logistic.read_rows() |> Enum.split_with(fn {_, _, split} -> split == "train" end)

# Scale with the training rows only. The leading 1 multiplies the intercept.
features = Enum.map(train, fn {x, _, _} -> x end)
ys = Enum.map(train, fn {_, y, _} -> y end)
cols = Logistic.columns(features)
means = Enum.map(cols, &Logistic.mean/1)
sds = Enum.map(cols, &Logistic.sd/1)
scale = fn x -> [1.0 | Enum.zip_with([x, means, sds], fn [v, m, s] -> (v - m) / s end)] end
xs = Enum.map(features, scale)

weights = Logistic.descend(xs, ys)
[intercept, weight_hours, weight_sleep] = weights
n = length(xs)

losses =
  Enum.zip_with(xs, ys, fn x, y ->
    p = Logistic.sigmoid(Logistic.dot(weights, x))
    y * :math.log(p) + (1 - y) * :math.log(1 - p)
  end)

log_loss = -Enum.sum(losses) / n

predict = fn x -> if Logistic.sigmoid(Logistic.dot(weights, scale.(x))) >= 0.5, do: 1, else: 0 end
correct = Enum.count(test, fn {x, y, _} -> predict.(x) == y end)

IO.puts("train_count #{n}")
IO.puts("test_count #{length(test)}")
Logistic.say("intercept", intercept)
Logistic.say("weight_hours", weight_hours)
Logistic.say("weight_sleep", weight_sleep)
Logistic.say("log_loss", log_loss)
IO.puts("correct #{correct}")
Logistic.say("accuracy", correct / length(test))
