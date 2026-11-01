⍝ Categorical naive Bayes with add-one (Laplace) smoothing, from scratch in
⍝ GNU APL. Each test email gets the label with the highest log-probability.
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
 T←((T[1]='.')/'0'),T        ⍝ ⍕ writes .94 for 0.94, so put the 0 back
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

F←⍉⊃COLUMN¨'has_link' 'mentions_money' 'known_sender'  ⍝ one row per email
L←COLUMN 'label'
⍝ 1 for each training row (≡ matches whole strings).
TRAIN←(COLUMN 'split')≡¨⊂'train'
TF←TRAIN⌿F ⋄ TL←TRAIN/L           ⍝ ⌿ keeps the training rows of a table
QF←(~TRAIN)⌿F ⋄ QL←(~TRAIN)/L     ⍝ ~ is not: the test rows

LABELS←∪TL
⍝ Alphabetical: ⊃ pads the names into a table, ⍋ sorts its rows.
LABELS←LABELS[⍋⊃LABELS]
⍝ m, per feature: ⊂[1] takes the columns; ≢∪ counts the unique values.
DISTINCT←{≢∪⍵}¨⊂[1]TF

∇S←ROW SCORE C;M;NC;COUNTS
 M←TL≡¨⊂C                         ⍝ 1 for the training rows labelled C
 NC←+/M                           ⍝ how many there are
 ⍝ Per feature: rows with label C and the same value.
 COUNTS←+⌿(M⌿TF)≡¨(NC,≢ROW)⍴ROW
 ⍝ ⍟ is the natural log. Summing logs multiplies the probabilities without
 ⍝ underflow, and the +1 keeps an unseen value from scoring zero.
 S←(⍟NC÷≢TL)++/⍟(COUNTS+1)÷NC+DISTINCT
∇

⍝ ⌈/ is the max; ⍳ finds its first position, so a tie goes to the first label.
CLASSIFY←{S←(⊂⍵)SCORE¨LABELS ⋄ ⊃LABELS[S⍳⌈/S]}
PRED←CLASSIFY¨⊂[2]QF              ⍝ ⊂[2] makes one item per test row
CORRECT←+/PRED≡¨QL

'train_count' SAY ≢TL
'test_count' SAY ≢QL
'correct' SAY CORRECT
'accuracy' SAY6 CORRECT÷≢QL
)OFF
