COBOL has no dictionaries, only fixed tables indexed by position. Nested
`OCCURS` clauses give a feature-by-value-by-label grid of counts,
`WS-VALUE-ROWS(F, V, L)`, but finding the right `V` or `L` means a linear
scan of the names seen so far, adding a new entry the first time one
appears. Since the data is all text, there is no number parsing at all.

Each log score is built from logs of whole counts, `FUNCTION LOG(WS-MATCHES
+ 1) - FUNCTION LOG(...)`, rather than the log of a quotient. Storing 17/57 in
a four-decimal field first would shift its log by about 0.00015.
GnuCOBOL's inline `FUNCTION LOG(A / B)` gave the precise value when we tried
it, but whole counts avoid the question. The program runs to 246 lines, about
five times the Python.
