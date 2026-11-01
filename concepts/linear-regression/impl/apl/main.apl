⍝ Simple linear regression by least squares, from scratch in GNU APL.
⍝ Fits score = intercept + slope × hours. APL reads right to left, with no
⍝ operator precedence: 2×3+4 is 2×(3+4). ⍝ starts a comment; ← assigns.

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
⍝ Find a column by header name (⍳), drop the header (1↓), and turn each
⍝ text into a number (⍎¨).
COLUMN←{⍎¨1↓ROWS[;ROWS[1;]⍳⊂⍵]}
X←COLUMN 'hours'
Y←COLUMN 'score'

N←≢X                        ⍝ ≢ counts the items
DX←X-(+/X)÷N                ⍝ deviations from the mean; +/ is the sum
DY←Y-(+/Y)÷N
SXX←+/DX*2                  ⍝ sum of squared deviations (* is power)
SYY←+/DY*2
SXY←+/DX×DY                 ⍝ sum of cross-products, pair by pair
SLOPE←SXY÷SXX
INTERCEPT←((+/Y)÷N)-SLOPE×(+/X)÷N
R←SXY÷(SXX×SYY)*0.5         ⍝ *0.5 is the square root

'count' SAY N
'slope' SAY6 SLOPE
'intercept' SAY6 INTERCEPT
'r' SAY6 R
'r_squared' SAY6 R*2
)OFF
