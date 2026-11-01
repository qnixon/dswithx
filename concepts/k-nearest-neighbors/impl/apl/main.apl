⍝ k-nearest neighbors classification, from scratch in GNU APL.
⍝ Each test seed gets the majority variety among its K nearest training
⍝ seeds. APL reads right to left, with no operator precedence: 2×3+4 is
⍝ 2×(3+4). ⍝ starts a comment; ← assigns; ⍵ is a function's right argument.

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

K←5

⍝ Read the file. ⎕ARG is the command line; ↑¯1↑ takes its last item, the
⍝ data path. ⎕FIO[26] reads the whole file as one string.
TEXT←⎕FIO[26]↑¯1↑⎕ARG
LINES←(TEXT≠⎕UCS 10)⊂TEXT   ⍝ ⊂ splits at the 0s of the mask: one item per line
⍝ Split each (¨) line at commas; ⊃ stacks them into a table.
ROWS←⊃{(⍵≠',')⊂⍵}¨LINES
⍝ A column by header name (⍳), minus the header (1↓).
COLUMN←{1↓ROWS[;ROWS[1;]⍳⊂⍵]}

⍝ 2-row table of numbers (⍎ turns text to number).
XY←⍎¨⊃COLUMN¨'length_mm' 'width_mm'
LABEL←COLUMN 'variety'
⍝ 1 for each training row (≡ matches whole strings).
TRAIN←(COLUMN 'split')≡¨⊂'train'
⍝ / keeps the training columns; ⍉ flips to one row per seed.
TP←⍉TRAIN/XY ⋄ TL←TRAIN/LABEL
QP←⍉(~TRAIN)/XY ⋄ QL←(~TRAIN)/LABEL   ⍝ ~ is not: the test rows

∇WINNER←CLASSIFY P;D;NEAR;KINDS;VOTES
 ⍝ Distance to every training seed: (⍴TP)⍴P repeats P per row.
 D←(+/(TP-(⍴TP)⍴P)*2)*0.5
 ⍝ ⍋ sorts stably, so equal distances keep file order.
 NEAR←TL[K↑⍋D]
 KINDS←∪NEAR                  ⍝ ∪ is unique, in order of first appearance
 ⍝ ∘.≡ compares every kind with every neighbor; +/ counts.
 VOTES←+/KINDS∘.≡NEAR
 ⍝ The first kind with the most votes (⌈/ is the max).
 WINNER←⊃KINDS[VOTES⍳⌈/VOTES]
∇

⍝ ⊂[2] makes one item per row, so ¨ classifies each test seed.
PRED←CLASSIFY¨⊂[2]QP
CORRECT←+/PRED≡¨QL

'train_count' SAY ≢TL
'test_count' SAY ≢QL
'correct' SAY CORRECT
'accuracy' SAY6 CORRECT÷≢QL
)OFF
