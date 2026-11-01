⍝ A decision tree classifier (CART with Gini impurity), from scratch in GNU
⍝ APL. Grows a tree on the training days by always making the split that
⍝ leaves the two sides purest, then predicts rain for the test days.
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

FEATURES←'humidity' 'pressure' 'wind'
MAX_DEPTH←3 ⋄ MIN_SIZE←5

⍝ Read the file. ⎕ARG is the command line; ↑¯1↑ takes its last item, the
⍝ data path. ⎕FIO[26] reads the whole file as one string.
TEXT←⎕FIO[26]↑¯1↑⎕ARG
LINES←(TEXT≠⎕UCS 10)⊂TEXT   ⍝ ⊂ splits at the 0s of the mask: one item per line
⍝ Split each (¨) line at commas; ⊃ stacks them into a table.
ROWS←⊃{(⍵≠',')⊂⍵}¨LINES
⍝ A column by header name (⍳), minus the header (1↓).
COLUMN←{1↓ROWS[;ROWS[1;]⍳⊂⍵]}

X←⍉⊃{⍎¨COLUMN ⍵}¨FEATURES    ⍝ one row per day; ⍎ turns text into a number
Y←(COLUMN 'rain')≡¨⊂'yes'    ⍝ 1 for a rainy day (≡ matches whole strings)
TRAIN←(COLUMN 'split')≡¨⊂'train'
TX←TRAIN⌿X ⋄ TY←TRAIN/Y      ⍝ ⌿ keeps the training rows of a table

⍝ Chance that two days drawn at random disagree, from the share ⍵ of rain.
GINI←{1-(⍵*2)+(1-⍵)*2}

∇R←Y SPLIT V;U;T;M;N;NL;YL;S
 ⍝ The best (score, threshold) for one feature's values V at a node.
 U←∪V ⋄ U←U[⍋U]              ⍝ the distinct values, sorted (⍋ is grade up)
 R←1 0 ⋄ →(1=≢U)/0           ⍝ one value: no split (score 1 never wins)
 T←((¯1↓U)+1↓U)÷2            ⍝ midpoints of neighboring values
 ⍝ ∘.≤ makes a table, one row per day and one column per threshold, with
 ⍝ a 1 where the day goes left. +⌿ counts down each column, and Y+.×
 ⍝ counts the rainy days among them, for every threshold at once.
 M←V∘.≤T ⋄ N←≢V ⋄ NL←+⌿M ⋄ YL←Y+.×M
 S←((NL×GINI YL÷NL)+(N-NL)×GINI((+/Y)-YL)÷N-NL)÷N
 R←(⌊/S),T[S⍳⌊/S]            ⍝ ⍳ finds the first minimum: smallest wins
∇

⍝ The tree is four vectors, one item per node in preorder. A split node has
⍝ a feature number (FEAT) and threshold; a leaf has FEAT 0 and a prediction.
⍝ A left child always comes next in preorder; RIGHT records the right one.
FEAT←THR←PRED←RIGHT←⍬

∇DEPTH GROW I;Y;N;G;B;F;K;L
 ⍝ Grow the node holding training rows I, then (recursively) its children.
 Y←TY[I] ⋄ N←≢I ⋄ G←GINI(+/Y)÷N
 ⍝ Add it as a leaf first; an even split predicts "no".
 ⍝ GNU APL has no FEAT,←0 shorthand, so each vector is rebuilt with , (join).
 FEAT←FEAT,0 ⋄ THR←THR,0 ⋄ RIGHT←RIGHT,0 ⋄ PRED←PRED,(+/Y)>N÷2
 K←≢FEAT ⋄ →((G=0)∨(N<MIN_SIZE)∨DEPTH=MAX_DEPTH)/0
 ⍝ ⊂[1] gives each feature's column; ⊃ stacks the results, one row each.
 B←⊃(⊂Y)SPLIT¨⊂[1]TX[I;]
 F←B[;1]⍳⌊/B[;1]             ⍝ the first feature with the lowest score
 →(B[F;1]≥G)/0               ⍝ no split makes the sides purer: stay a leaf
 FEAT[K]←F ⋄ THR[K]←B[F;2]
 L←TX[I;F]≤THR[K]
 (DEPTH+1)GROW L/I
 RIGHT[K]←1+≢FEAT            ⍝ the right subtree starts after the left
 (DEPTH+1)GROW(~L)/I
∇

0 GROW⍳≢TY

∇P←WALK DAY;K
 ⍝ Follow the splits from the root (node 1) down to a leaf.
 K←1
NEXT: →(FEAT[K]=0)/LEAF          ⍝ → jumps to a label when its argument is 1
 ⍝ The two children are K+1 and RIGHT[K]; > picks the right one (index 2).
 K←((K+1),RIGHT[K])[1+DAY[FEAT[K]]>THR[K]]
 →NEXT
LEAF: P←PRED[K]
∇

⍝ How many of the days in rows ⍵ the tree gets right.
CORRECT←{+/Y[⍵]=WALK¨⊂[2]X[⍵;]}
TRAINED←CORRECT TRAIN/⍳≢Y ⋄ TESTED←CORRECT(~TRAIN)/⍳≢Y

∇SHOW K;NODE
 NODE←'node_',(⍕K),'_'
 →(FEAT[K]=0)/LEAF
 ⎕←NODE,'feature ',⊃FEATURES[FEAT[K]]
 (NODE,'threshold')SAY6 THR[K]
 →0
LEAF: ⎕←NODE,'predict ',⊃('no' 'yes')[1+PRED[K]]
∇

'train_count' SAY +/TRAIN
'test_count' SAY +/~TRAIN
SHOW¨⍳≢FEAT
'leaves' SAY +/FEAT=0
'train_accuracy' SAY6 TRAINED÷+/TRAIN
'correct' SAY TESTED
'accuracy' SAY6 TESTED÷+/~TRAIN
)OFF
