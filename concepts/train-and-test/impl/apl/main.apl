⍝ Train and test error for polynomials of degree 1 to 8, from scratch in GNU
⍝ APL. Each polynomial is fitted by least squares to the training drives
⍝ only: we build the normal equations and solve them by Gaussian
⍝ elimination. Then we measure its root-mean-square error on the training
⍝ drives and on the test drives it never saw.
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

MAX_DEGREE←8

⍝ Read the file. ⎕ARG is the command line; ↑¯1↑ takes its last item, the
⍝ data path. ⎕FIO[26] reads the whole file as one string.
TEXT←⎕FIO[26]↑¯1↑⎕ARG
LINES←(TEXT≠⎕UCS 10)⊂TEXT   ⍝ ⊂ splits at the 0s of the mask: one item per line
⍝ Split each (¨) line at commas; ⊃ stacks them into a table.
ROWS←⊃{(⍵≠',')⊂⍵}¨LINES
⍝ A column by header name (⍳), minus the header (1↓).
COLUMN←{1↓ROWS[;ROWS[1;]⍳⊂⍵]}

SPEED←⍎¨COLUMN 'speed'        ⍝ ⍎ turns text to a number
LITRES←⍎¨COLUMN 'litres'
⍝ 1 for each training row (≡ matches whole strings); / keeps those rows.
TRAIN←(COLUMN 'split')≡¨⊂'train'
TX←TRAIN/SPEED ⋄ TY←TRAIN/LITRES
QX←(~TRAIN)/SPEED ⋄ QY←(~TRAIN)/LITRES   ⍝ ~ is not: the test rows

⍝ Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
⍝ largest entry at degree 8) would swamp the small ones and make the
⍝ equations hard to solve accurately. ⌈/ is the largest, ⌊/ the smallest.
MID←((⌈/TX)+⌊/TX)÷2 ⋄ HALF←((⌈/TX)-⌊/TX)÷2
SCALE←{(⍵-MID)÷HALF}

∇X←SOLVE M;N;K;P;V;R;C
 ⍝ Solve the augmented system M (N rows, N + 1 columns, b last) by
 ⍝ Gaussian elimination with partial pivoting.
 N←≢M ⋄ K←1
PIVOT:
 ⍝ Swap up the row with the largest entry in column K, at or below row K,
 ⍝ which keeps the rounding error small. Indexing with K,P on both sides
 ⍝ swaps the two rows in one assignment.
 V←|M[(K-1)↓⍳N;K]
 P←(K-1)+V⍳⌈/V         ⍝ ⍳ finds the first largest
 M[K,P;]←M[P,K;]
 ⍝ Every row below K subtracts a multiple of row K at once: the outer
 ⍝ product ∘.× makes the table of factor × row K entry.
 R←K↓⍳N ⋄ C←(K-1)↓⍳N+1
 M[R;C]←M[R;C]-(M[R;K]÷M[K;K])∘.×M[K;C]
 K←K+1 ⋄ →(K≤N)/PIVOT
 ⍝ Back substitution, from the last unknown up.
 X←N⍴0 ⋄ K←N
BACK:
 R←K↓⍳N                       ⍝ the unknowns already found
 X[K]←(M[K;N+1]-M[K;R]+.×X[R])÷M[K;K]
 K←K-1 ⋄ →(K≥1)/BACK
∇

∇COEFS←FIT D;Z;E;A;B
 ⍝ Least squares: the coefficients solve (Z^T Z) c = Z^T y. E is the table
 ⍝ of exponents i + j; Z∘.*E raises every speed to every one of them, and
 ⍝ +⌿ sums over the speeds, so A[i;j] is the sum of z^(i+j).
 Z←SCALE TX
 E←(0,⍳D)∘.+0,⍳D
 A←+⌿Z∘.*E
 B←TY+.×Z∘.*0,⍳D              ⍝ the sum of y × z^i, for each i
 COEFS←SOLVE A,B              ⍝ , joins B on as the last column
∇

∇E←COEFS RMSE XY;P
 ⍝ XY is speeds and litres; each prediction is the powers of z times the
 ⍝ coefficients. *0.5 is the square root.
 P←((SCALE⊃XY[1])∘.*¯1+⍳≢COEFS)+.×COEFS
 E←((+/(P-⊃XY[2])*2)÷≢P)*0.5
∇

'train_count' SAY ≢TX
'test_count' SAY ≢QX
DEGREES←⍳MAX_DEGREE
FITS←FIT¨DEGREES
⍝ ⊂ encloses the prefix so ,¨ joins it to each degree's text, and ⊂ around
⍝ each pair of vectors lets ¨ hand the same data to every fit.
((⊂'train_rmse_d'),¨⍕¨DEGREES) SAY6¨FITS RMSE¨⊂TX TY
((⊂'test_rmse_d'),¨⍕¨DEGREES) SAY6¨FITS RMSE¨⊂QX QY
)OFF
