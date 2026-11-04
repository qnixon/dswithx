⍝ Evaluation metrics for a binary classifier, from scratch in GNU APL.
⍝ Reads each part's true label and the model's score, then reports the
⍝ confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
⍝ the accuracy of never flagging anything, and the area under the ROC curve.
⍝ APL reads right to left, with no operator precedence: 2×3+4 is 2×(3+4).
⍝ ⍝ starts a comment; ← assigns; ⍵ is a function's right argument.

∇NAME SAY N
 ⍝ Print "name value" for a whole number. ⍕ formats a number as text.
 ⎕←NAME,' ',⍕N
∇

∇NAME SAY6 X;T
 ⍝ Print "name value" with six decimal places.
 T←0 6⍕|X                    ⍝ |X is the size of X; 0 6⍕ gives 6 decimals
 T←(∨\T≠' ')/T               ⍝ drop the leading blank ⍕ adds
 T←((T[1]='.')/'0'),T        ⍝ ⍕ writes .835 for 0.835, so put the 0 back
 ⎕←NAME,' ',((X<0)/'-'),T    ⍝ sign as -, since APL's own minus is ¯
∇

⍝ Read the file. ⎕ARG is the command line; ↑¯1↑ takes its last item, the
⍝ data path. ⎕FIO[26] reads the whole file as one string.
TEXT←⎕FIO[26]↑¯1↑⎕ARG
LINES←(TEXT≠⎕UCS 10)⊂TEXT   ⍝ ⊂ splits at the 0s of the mask: one item per line
⍝ Split each (¨) line at commas; ⊃ stacks them into a table.
ROWS←⊃{(⍵≠',')⊂⍵}¨LINES
⍝ A column by header name (⍳), minus the header (1↓).
COLUMN←{1↓ROWS[;ROWS[1;]⍳⊂⍵]}

DEFECTIVE←⍎¨COLUMN 'defective'   ⍝ ⍎ turns text into a number: 1s and 0s
SCORE←⍎¨COLUMN 'score'
N←≢SCORE                         ⍝ ≢ counts the items

∇SUFFIX REPORT THRESHOLD;FLAGGED;TP;FP;FN;TN;PRECISION;RECALL
 ⍝ Sort every part into one of four counts at this threshold, then print
 ⍝ the counts and the ratios built from them. Each count is the sum (+/)
 ⍝ of a 1-or-0 mask: ∧ is and, ~ is not.
 FLAGGED←SCORE≥THRESHOLD      ⍝ flagged when the score reaches it
 TP←+/FLAGGED∧DEFECTIVE
 FP←+/FLAGGED∧~DEFECTIVE
 FN←+/(~FLAGGED)∧DEFECTIVE
 TN←+/(~FLAGGED)∧~DEFECTIVE
 PRECISION←TP÷TP+FP           ⍝ of the flagged, how many are defective
 RECALL←TP÷TP+FN              ⍝ of the defective, how many are flagged
 ('tp_at_',SUFFIX) SAY TP
 ('fp_at_',SUFFIX) SAY FP
 ('fn_at_',SUFFIX) SAY FN
 ('tn_at_',SUFFIX) SAY TN
 ('accuracy_at_',SUFFIX) SAY6 (TP+TN)÷N
 ('precision_at_',SUFFIX) SAY6 PRECISION
 ('recall_at_',SUFFIX) SAY6 RECALL
 ('f1_at_',SUFFIX) SAY6 (2×PRECISION×RECALL)÷PRECISION+RECALL
∇

'parts' SAY N
'defective' SAY +/DEFECTIVE
⍝ Never flagging anything is right about every good part.
'baseline_accuracy' SAY6 (N-+/DEFECTIVE)÷N
'50' REPORT 0.5
'30' REPORT 0.3

⍝ The AUC: the chance that a random defective part outscores a random good
⍝ one. / keeps the scores where the mask is 1. The outer product ∘.> compares
⍝ every defective score with every good score at once, giving a table of 1s
⍝ and 0s, one row per defective part and one column per good part; ∘.=
⍝ does the same for ties. A win scores 2 and a tie 1, and , flattens the
⍝ table so +/ can add it up, a whole number until the final division.
D←DEFECTIVE/SCORE
G←(~DEFECTIVE)/SCORE
POINTS←+/,(2×D∘.>G)+D∘.=G
'auc' SAY6 POINTS÷2×(≢D)×≢G
)OFF
