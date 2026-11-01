The table of text values is nested: each cell holds a string like `yes`, so
`≡¨` compares whole strings item by item. Scoring one label is three steps:
keep the training rows with that label (`⌿`), count the rows that match the
test email in each feature, and sum the logs (`⍟`) of the smoothed
fractions. `≢∪` counts each feature's distinct values for the smoothing.

For the tie rule, `⊃` pads the label names into a character table and `⍋`
sorts its rows alphabetically, so `⍳` finding the first maximum score picks
the alphabetically first label. APL has no probability built-ins, so nothing
is avoided.
