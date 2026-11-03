We read each row into a map from column name to value, then count the
training rows with `Enum.frequencies`, which turns a list into a map from
each distinct item to how often it appears. The value counts use a
`{feature, value, label}` tuple as the key, and `Map.get` with a default of
0 covers a combination never seen.

Neither Elixir nor Erlang ships a naive Bayes classifier, and Hex packages
aren't installed. Scoring adds logarithms from Erlang's `:math.log`, with
add-one smoothing. We sort the labels and pick with `Enum.max_by`, which
keeps the first of equal scores, so an exact tie goes to the alphabetically
first label.
