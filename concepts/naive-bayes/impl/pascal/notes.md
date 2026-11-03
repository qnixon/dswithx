Each email is a `TRow` record holding its three feature values, label,
and split. `label` is a reserved word in Pascal, so the field is `Label_`.
We keep no table of counts, since `TDictionary` won't compile here with
warnings as errors: `CountRows` recounts matching training rows each time
a score needs one.

The distinct labels go through `TArrayHelper<String>.Sort`, which orders
by character code, so `'Spam'` would sort before `'ham'`; all our labels
are lowercase. Only a strictly higher score replaces the best, so an exact
tie goes to the alphabetically first label. `Ln` takes the logs, and none
of the installed units has a naive Bayes routine to avoid.
