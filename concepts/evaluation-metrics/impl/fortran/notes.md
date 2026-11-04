We keep two arrays, one of logical labels and one of scores, and work on
whole arrays at once. `score >= threshold` gives one `.true.` or `.false.`
per part, and `count` of a mask such as `flagged .and. defective` gives
each cell of the confusion matrix with no loop.

For the AUC, `pack` keeps the good scores, and each defective score is
compared against all of them in one expression: twice the count of good
scores below it, plus the count equal to it. That adds up 33 times 167
pairs while the total stays an integer.
