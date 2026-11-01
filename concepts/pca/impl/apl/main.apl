⍝ Principal component analysis by power iteration, from scratch in GNU APL.
⍝ Standardizes the four scores, builds their correlation matrix, and finds
⍝ the top two eigenvectors (the principal components): power iteration finds
⍝ the first, then deflation removes it from the matrix so the same steps find
⍝ the second. APL reads right to left, with no operator precedence: 2×3+4 is
⍝ 2×(3+4). ⍝ starts a comment; ← assigns.

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

STEPS←1000
SUBJECTS←'math' 'physics' 'reading' 'writing'

⍝ Read the file. ⎕ARG is the command line; ↑¯1↑ takes its last item, the
⍝ data path. ⎕FIO[26] reads the whole file as one string.
TEXT←⎕FIO[26]↑¯1↑⎕ARG
LINES←(TEXT≠⎕UCS 10)⊂TEXT   ⍝ ⊂ splits at the 0s of the mask: one item per line
⍝ Split each (¨) line at commas; ⊃ stacks them into a table.
ROWS←⊃{(⍵≠',')⊂⍵}¨LINES
⍝ A column by header name (⍳), minus the header (1↓); ⍎¨ makes numbers.
COLUMN←{⍎¨1↓ROWS[;ROWS[1;]⍳⊂⍵]}
X←⍉⊃COLUMN¨SUBJECTS         ⍝ one row per student, one column per subject
N←≢X ⋄ K←≢SUBJECTS          ⍝ ≢ counts the items

⍝ Standardize each column to mean 0 and sample standard deviation 1. ⌿ works
⍝ down the columns: +⌿ sums each one. (⍴X)⍴ repeats a row of column values
⍝ on every row, and *0.5 is the square root.
C←X-(⍴X)⍴(+⌿X)÷N
Z←C÷(⍴X)⍴((+⌿C*2)÷N-1)*0.5

⍝ The correlation matrix. ⍉ transposes, and the matrix product (⍉Z)+.×Z
⍝ sums z_i × z_j over the students for every pair of columns at once.
CORR←((⍉Z)+.×Z)÷N-1

NORMALIZE←{⍵÷(+/⍵×⍵)*0.5}   ⍝ divide by the length

∇V←TOP M;START
 ⍝ Power iteration: multiply by M and rescale, STEPS times. The power
 ⍝ operator ⍣ repeats the step, starting from 1 0 0 0: (≢M)↑1 pads 1 with
 ⍝ zeros to M's size.
 START←(≢M)↑1
 V←({NORMALIZE M+.×⍵}⍣STEPS)START
 ⍝ An eigenvector can point either way; make its first entry positive.
 ⍝ ¯1*1 is ¯1 and ¯1*0 is 1, so this flips V only when V[1]<0.
 V←V×¯1*V[1]<0
∇

⍝ The eigenvalue is the Rayleigh quotient v·(M v).
EIGENVALUE←{⍵+.×⍺+.×⍵}

PC1←TOP CORR
VALUE1←CORR EIGENVALUE PC1
⍝ Deflation: subtract the first component's share, leaving the rest.
⍝ The outer product PC1∘.×PC1 is the K-by-K table of v_i × v_j.
DEFLATED←CORR-VALUE1×PC1∘.×PC1
PC2←TOP DEFLATED
VALUE2←DEFLATED EIGENVALUE PC2

'count' SAY N
⍝ Standardized columns each have variance 1, so the total is K.
'eigenvalue_1' SAY6 VALUE1
'explained_1' SAY6 VALUE1÷K
⍝ Each label is 'pc1_' joined (,) to a subject name, and SAY6¨ pairs each
⍝ label with its loading.
({'pc1_',⍵}¨SUBJECTS) SAY6¨PC1
'eigenvalue_2' SAY6 VALUE2
'explained_2' SAY6 VALUE2÷K
({'pc2_',⍵}¨SUBJECTS) SAY6¨PC2
⍝ A student's score on a component is the dot product z·v.
'student_1_pc1' SAY6 Z[1;]+.×PC1
'student_1_pc2' SAY6 Z[1;]+.×PC2
)OFF
