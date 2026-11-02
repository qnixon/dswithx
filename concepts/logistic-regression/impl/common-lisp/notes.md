The training rows are a list of lists, and the weights are a list of three
numbers. `step-weights` works out every student's error from the old
weights, then builds a new list with `mapcar`, so every weight moves from
the same gradient and nothing is changed in place. `(apply #'mapcar #'list
rows)` turns rows into columns, so each weight's gradient is one `dot`.

Watch the decimals in the file itself. The compiler reads the whole file
before the program runs, so a plain `setf` of `*read-default-float-format*`
would leave a bare `0.5` there a single float; `eval-when` makes it apply
while compiling, too. And watch `*features*`: it's already a standard
variable, so naming our list that stops the compile.
