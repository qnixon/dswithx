⍝ Descriptive statistics on one CSV column, from scratch in GNU APL.
⍝ APL reads right to left, with no operator precedence: 2×3+4 is 2×(3+4).
⍝ ⍝ starts a comment, and ← assigns.

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
COL←ROWS[1;]⍳⊂'minutes'     ⍝ ⍳ finds the column by its header name
⍝ Drop the header (1↓) and turn each text into a number (⍎¨).
X←⍎¨1↓ROWS[;COL]

⍝ ⍋ gives the indices that sort X; indexing with them sorts.
S←X[⍋X]
N←≢X                        ⍝ ≢ counts the items
MEAN←(+/X)÷N                ⍝ +/ puts + between the items: the sum
MID←(N+1)÷2                 ⍝ 60.5 for 120 values
MEDIAN←(+/S[(⌊MID),⌈MID])÷2 ⍝ average the values at the floor and ceiling of MID
⍝ Sample variance; right to left, so ÷N-1 divides by N-1.
VAR←(+/(X-MEAN)*2)÷N-1

'count' SAY N
'sum' SAY6 +/X
'mean' SAY6 MEAN
'median' SAY6 MEDIAN
'min' SAY6 S[1]             ⍝ APL counts from 1 (⎕IO is 1)
'max' SAY6 S[N]
'range' SAY6 S[N]-S[1]
'variance' SAY6 VAR
'std_dev' SAY6 VAR*0.5      ⍝ * is power, so *0.5 is the square root
)OFF
