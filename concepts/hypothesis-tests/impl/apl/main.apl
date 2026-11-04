⍝ Exact two-sided permutation test for a difference in means, from scratch
⍝ in GNU APL. If compost made no difference, the "compost" and "control"
⍝ labels are arbitrary, and any 8 of the 16 plants could have carried the
⍝ compost label. We try every one of those splits and count how many give a
⍝ difference at least as large as the one we observed.
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
 T←((T[1]='.')/'0'),T        ⍝ ⍕ writes .03 for 0.03, so put the 0 back
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

GRAMS←⍎¨COLUMN 'grams'                 ⍝ ⍎ turns text into a number
COMPOST←(COLUMN 'group')≡¨⊂'compost'   ⍝ 1 for each compost plant
N←+/COMPOST                            ⍝ the compost group's size
CONTROLSUM←+/(~COMPOST)/GRAMS          ⍝ ~ is not; / keeps where the mask is 1
COMPOSTSUM←+/COMPOST/GRAMS
TOTAL←+/GRAMS
⍝ Both groups have the same size, so comparing totals is the same as
⍝ comparing means, and totals stay whole numbers: no floating-point near-ties.
OBSERVED←COMPOSTSUM-CONTROLSUM

⍝ Every split at once. (P⍴2)⊤ writes each whole number from 0 to 2*P - 1 in
⍝ base 2, one column per number and one row per plant: a 16 by 65536 table
⍝ of 0s and 1s, where 1 means "labeled compost".
P←≢GRAMS
MASKS←(P⍴2)⊤¯1+⍳2*P
⍝ +⌿ sums each column; keep (/) the columns with exactly N ones.
MASKS←(N=+⌿MASKS)/MASKS
⍝ +.× is the matrix product: each split's chosen grams in one step.
CHOSEN←GRAMS+.×MASKS
DIFFERENCE←CHOSEN-TOTAL-CHOSEN         ⍝ right to left: CHOSEN-(TOTAL-CHOSEN)
SPLITS←≢CHOSEN
ASEXTREME←+/(|DIFFERENCE)≥|OBSERVED    ⍝ two-sided: | is absolute value

'control_count' SAY +/~COMPOST
'compost_count' SAY N
'control_mean' SAY6 CONTROLSUM÷N
'compost_mean' SAY6 COMPOSTSUM÷N
'observed_difference' SAY6 OBSERVED÷N
'splits' SAY SPLITS
'as_extreme' SAY ASEXTREME
'p_value' SAY6 ASEXTREME÷SPLITS
)OFF
