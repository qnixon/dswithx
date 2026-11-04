⍝ 5-fold cross-validation for k-nearest neighbors, from scratch in GNU APL.
⍝ Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
⍝ holding out one fold at a time, picks the k with the best average
⍝ accuracy, and then scores that k once on the untouched test seeds.
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

FOLDS←5
KS←¯1+2×⍳8                    ⍝ 1 3 5 … 15: odd k only, so no tied votes

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
 ⍝ RP, RL, and K belong to CORRECT below. APL names are dynamically
 ⍝ scoped, so a function sees the locals of the one that called it.
 D←(+/(RP-(⍴RP)⍴P)*2)*0.5     ⍝ distance to every reference seed
 NEAR←RL[K↑⍋D]                ⍝ ⍋ sorts stably: ties keep file order
 KINDS←∪NEAR                  ⍝ ∪ is unique, in order of first appearance
 VOTES←+/KINDS∘.≡NEAR         ⍝ ∘.≡ compares every kind with every neighbor
 WINNER←⊃KINDS[VOTES⍳⌈/VOTES] ⍝ the first kind with the most votes
∇

∇C←K CORRECT SETS;QP;QL;RP;RL
 ⍝ SETS holds query points, query labels, reference points, and reference
 ⍝ labels; this assigns all four at once. C counts correct query labels.
 (QP QL RP RL)←SETS
 C←+/(CLASSIFY¨⊂[2]QP)≡¨QL    ⍝ ⊂[2] makes one item per row for ¨
∇

∇ACC←CV K;N;SIZE;F;FOLD;HELD
 ⍝ The average accuracy of K over the folds.
 N←≢TL ⋄ SIZE←N÷FOLDS ⋄ FOLD←⌈(⍳N)÷SIZE   ⍝ each row's fold: 1 1 … 5 5
 ACC←0 ⋄ F←1
NEXT:
 HELD←FOLD=F                  ⍝ a mask: 1 for the rows of fold F
 ⍝ ⌿ keeps the rows of a table where the mask is 1.
 ACC←ACC+K CORRECT (HELD⌿TP)(HELD/TL)((~HELD)⌿TP)((~HELD)/TL)
 F←F+1 ⋄ →(F≤FOLDS)/NEXT      ⍝ jump back while folds remain
 ACC←ACC÷N
∇

'train_count' SAY ≢TL
'test_count' SAY ≢QL
ACCS←CV¨KS                    ⍝ score every k at once
⍝ ⊂ encloses the prefix so ,¨ joins it to each k's text.
((⊂'cv_accuracy_k'),¨⍕¨KS) SAY6¨ACCS
⍝ ⍳ finds the first top accuracy, so a tie goes to the smaller k.
BEST←KS[ACCS⍳⌈/ACCS]
⍝ Only now touch the test seeds, once, with the chosen k and all of train.
TESTC←BEST CORRECT QP QL TP TL
'best_k' SAY BEST
'test_correct' SAY TESTC
'test_accuracy' SAY6 TESTC÷≢QL
)OFF
