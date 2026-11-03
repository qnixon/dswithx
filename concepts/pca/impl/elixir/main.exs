# Principal component analysis by power iteration, using only Elixir's
# standard library.
#
# Standardizes the four scores, builds their correlation matrix, and finds the
# top two eigenvectors (the principal components): power iteration finds the
# first, then deflation removes it from the matrix so the same steps find the
# second. A matrix is a list of row lists, and nothing is changed in place.

defmodule PCA do
  @subjects ~w(math physics reading writing)   # ~w splits words into a list
  @steps 1000

  def subjects, do: @subjects

  # The subject columns of every row, read as floats, in the order above.
  def read_rows(path) do
    [header | lines] = path |> File.read!() |> String.split("\n", trim: true)
    names = String.split(header, ",")
    indexes = Enum.map(@subjects, fn s -> Enum.find_index(names, &(&1 == s)) || raise "column not found: #{s}" end)

    Enum.map(lines, fn line ->
      fields = String.split(line, ",")
      # Float.parse returns {number, rest}; "82" parses as 82.0 too.
      Enum.map(indexes, fn i -> {value, ""} = fields |> Enum.at(i) |> Float.parse(); value end)
    end)
  end

  # zip_reduce walks two lists side by side, carrying a running total.
  def dot(u, v), do: Enum.zip_reduce(u, v, 0.0, fn a, b, acc -> acc + a * b end)

  # A matrix times a vector: each row dotted with the vector.
  def mat_vec(m, v), do: Enum.map(m, &dot(&1, v))

  def normalize(v) do
    length = :math.sqrt(dot(v, v))
    Enum.map(v, &(&1 / length))
  end

  # The columns of a list of rows: zip_with gathers the first of every row,
  # then the second, and so on.
  def columns(rows), do: Enum.zip_with(rows, & &1)

  # Power iteration: multiply by the matrix and rescale, 1,000 times.
  # Returns {eigenvalue, eigenvector}.
  def top_eigenvector(m) do
    start = [1.0 | List.duplicate(0.0, length(m) - 1)]
    # reduce threads v through every step; _ ignores the step number.
    v = Enum.reduce(1..@steps, start, fn _, v -> normalize(mat_vec(m, v)) end)
    # An eigenvector can point either way; make its first entry positive.
    v = if hd(v) < 0, do: Enum.map(v, &(-&1)), else: v
    {dot(v, mat_vec(m, v)), v}
  end

  def say(name, value), do: IO.puts("#{name} #{:erlang.float_to_binary(value, decimals: 6)}")
end

[path] = System.argv()
rows = PCA.read_rows(path)
n = length(rows)
k = length(PCA.subjects())

# Standardize each column to mean 0 and (sample) standard deviation 1.
cols = PCA.columns(rows)
means = Enum.map(cols, fn c -> Enum.sum(c) / n end)

sds =
  Enum.zip_with(cols, means, fn c, m ->
    :math.sqrt((c |> Enum.map(&((&1 - m) ** 2)) |> Enum.sum()) / (n - 1))
  end)

z = Enum.map(rows, fn row -> Enum.zip_with([row, means, sds], fn [x, m, s] -> (x - m) / s end) end)

# The correlation matrix: the covariance of the standardized columns.
zcols = PCA.columns(z)
corr = for a <- zcols, do: for(b <- zcols, do: PCA.dot(a, b) / (n - 1))

{value_1, pc_1} = PCA.top_eigenvector(corr)
# Deflation: subtract the first component's share, leaving the rest.
deflated =
  Enum.zip_with(corr, pc_1, fn row, a ->
    Enum.zip_with(row, pc_1, fn c, b -> c - value_1 * a * b end)
  end)

{value_2, pc_2} = PCA.top_eigenvector(deflated)

IO.puts("count #{n}")

for {{value, pc}, c} <- Enum.with_index([{value_1, pc_1}, {value_2, pc_2}], 1) do
  PCA.say("eigenvalue_#{c}", value)
  # Standardized columns each have variance 1, so the total is k.
  PCA.say("explained_#{c}", value / k)
  for {subject, loading} <- Enum.zip(PCA.subjects(), pc), do: PCA.say("pc#{c}_#{subject}", loading)
end

PCA.say("student_1_pc1", PCA.dot(hd(z), pc_1))
PCA.say("student_1_pc2", PCA.dot(hd(z), pc_2))
