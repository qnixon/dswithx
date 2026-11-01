⍝ k-means clustering (Lloyd's algorithm), from scratch in GNU APL.
⍝ Start from the first K points, then alternate two steps until no point
⍝ changes cluster: assign each point to its nearest centroid, and move each
⍝ centroid to the mean of its points. APL reads right to left, with no
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

K←3 ⋄ MAX_ITERATIONS←100

⍝ Read the file. ⎕ARG is the command line; ↑¯1↑ takes its last item, the
⍝ data path. ⎕FIO[26] reads the whole file as one string.
TEXT←⎕FIO[26]↑¯1↑⎕ARG
LINES←(TEXT≠⎕UCS 10)⊂TEXT   ⍝ ⊂ splits at the 0s of the mask: one item per line
⍝ Split each (¨) line at commas; ⊃ stacks them into a table.
ROWS←⊃{(⍵≠',')⊂⍵}¨LINES
⍝ A column by header name (⍳), minus the header (1↓), as numbers (⍎¨).
⍝ , turns a one-letter name like 'x' into a string; ⍉ makes one row per point.
COLUMN←{⍎¨1↓ROWS[;ROWS[1;]⍳⊂,⍵]}
P←⍉⊃COLUMN¨'x' 'y'

∇A←NEAREST C;D
 ⍝ Distance from every point (rows) to every centroid (columns): ∘.- subtracts
 ⍝ each centroid's coordinate from each point's, making a table.
 D←(((P[;1]∘.-C[;1])*2)+(P[;2]∘.-C[;2])*2)*0.5
 ⍝ Per row: where (⍳) is its minimum (⌊/)? Ties go to the first.
 A←{⍵⍳⌊/⍵}¨⊂[2]D
∇

∇C←C MOVE A;B;N;E
 B←A∘.=⍳K                    ⍝ table with a 1 where point i is in cluster j
 N←+⌿B                       ⍝ cluster sizes: +⌿ sums down each column
 ⍝ Clusters with points; an empty one keeps its centroid.
 E←(N>0)/⍳K
 ⍝ (⍉B)+.×P is a matrix product: it sums each cluster's points. Dividing by
 ⍝ the cluster's size, repeated for x and y (∘.×1 1), gives the mean.
 C[E;]←((⍉B)+.×P)[E;]÷N[E]∘.×1 1
∇

∇KMEANS;NEW
 C←K↑[1]P ⋄ A←0 ⋄ ITERATIONS←0    ⍝ the first K rows are the starting centroids
NEXT: ITERATIONS←ITERATIONS+1
 NEW←NEAREST C
 ⍝ → jumps; /0 leaves the function once nothing changes.
 →(NEW≡A)/0
 A←NEW
 C←C MOVE A
 →(ITERATIONS<MAX_ITERATIONS)/NEXT
∇

KMEANS
'iterations' SAY ITERATIONS
⍝ SAY¨ prints one line per name and value. ∘., joins every prefix with x and y;
⍝ , flattens the table row by row, the same order as ,C.
(,({'centroid_',(⍕⍵),'_'}¨⍳K)∘.,'xy') SAY6¨ ,C
({'size_',⍕⍵}¨⍳K) SAY¨ +⌿A∘.=⍳K
⍝ C[A;] is each point's own centroid; , flattens.
'inertia' SAY6 +/,(P-C[A;])*2
)OFF
