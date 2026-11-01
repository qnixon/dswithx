⍝ Logistic regression by gradient descent, from scratch in GNU APL.
⍝ Predicts whether a student passed from study hours and sleep. Each feature
⍝ is rescaled with the training rows' mean and sample standard deviation, then
⍝ the weights start at zero and take STEPS steps of batch gradient descent on
⍝ the average log-loss. APL reads right to left, with no operator precedence:
⍝ 2×3+4 is 2×(3+4). ⍝ starts a comment; ← assigns.

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

RATE←0.5 ⋄ STEPS←1000

⍝ Read the file. ⎕ARG is the command line; ↑¯1↑ takes its last item, the
⍝ data path. ⎕FIO[26] reads the whole file as one string.
TEXT←⎕FIO[26]↑¯1↑⎕ARG
LINES←(TEXT≠⎕UCS 10)⊂TEXT   ⍝ ⊂ splits at the 0s of the mask: one item per line
⍝ Split each (¨) line at commas; ⊃ stacks them into a table.
ROWS←⊃{(⍵≠',')⊂⍵}¨LINES
⍝ A column by header name (⍳), minus the header (1↓); ⍎¨ makes numbers.
TEXTS←{1↓ROWS[;ROWS[1;]⍳⊂⍵]}
COLUMN←{⍎¨TEXTS ⍵}
F←⍉⊃COLUMN¨'hours' 'sleep'  ⍝ one row per student, one column per feature
Y←COLUMN 'passed'
TRAIN←(TEXTS 'split')∊⊂'train'  ⍝ 1 for a training row, 0 for a test row

⍝ Training mean and sample standard deviation of each column. ⌿ works down
⍝ the columns: +⌿ sums each one, and TRAIN⌿ keeps the training rows.
FT←TRAIN⌿F
N←≢FT                       ⍝ ≢ counts the rows
MEAN←(+⌿FT)÷N
⍝ (⍴FT)⍴MEAN repeats the means on every row; *0.5 is the square root.
SD←((+⌿(FT-(⍴FT)⍴MEAN)*2)÷N-1)*0.5
⍝ Scale every row with the training statistics, and put a 1 in front (1,)
⍝ to multiply the intercept.
X←1,(F-(⍴F)⍴MEAN)÷(⍴F)⍴SD
XT←TRAIN⌿X ⋄ YT←TRAIN/Y

SIGMOID←{÷1+*-⍵}            ⍝ monadic ÷ is 1÷; monadic * is e to the power

⍝ One step from weights ⍵. XT+.×⍵ is a matrix product: every row's w·x.
⍝ Minus YT gives each row's error p - y. A second product, errors +.×XT,
⍝ sums error × input for each weight, and ÷N turns the sums into means.
GRADIENT←{(((SIGMOID XT+.×⍵)-YT)+.×XT)÷N}
STEP←{⍵-RATE×GRADIENT ⍵}    ⍝ all three weights move together

⍝ The power operator ⍣ applies STEP STEPS times, starting from 3⍴0: three
⍝ weights of 0.
W←(STEP⍣STEPS)3⍴0
P←SIGMOID XT+.×W
LOSS←-(+/(YT×⍟P)+(1-YT)×⍟1-P)÷N  ⍝ ⍟ is the natural log
⍝ ~ is not: the test rows. Predict 1 when p ≥ 0.5, and count the matches.
PREDICTED←0.5≤SIGMOID((~TRAIN)⌿X)+.×W
CORRECT←+/PREDICTED=(~TRAIN)/Y

'train_count' SAY N
'test_count' SAY +/~TRAIN
'intercept' SAY6 W[1]
'weight_hours' SAY6 W[2]
'weight_sleep' SAY6 W[3]
'log_loss' SAY6 LOSS
'correct' SAY CORRECT
'accuracy' SAY6 CORRECT÷+/~TRAIN
)OFF
