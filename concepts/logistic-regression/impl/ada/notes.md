We hold each student as a record: an `Inputs` array whose entry 0 is
always 1, so weight 0 acts as the intercept, plus the 0 or 1 label. Ada's
standard library has no mean, standard deviation, or logistic regression,
so the scaling and every gradient step are written out as loops, and the
gradient is summed over all 150 training students before any weight
moves. Writing `for R of Train loop` over a vector variable lets you
change each row in place. `Boolean'Pos` turns a prediction into 0 or 1, so
it can be compared with the label. Alire crates aren't installed.
