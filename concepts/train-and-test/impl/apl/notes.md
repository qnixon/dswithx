We keep the augmented system as an ordinary APL matrix, so whole rows are
one index away. The pivot swap is a single assignment,
`M[K,P;]←M[P,K;]`, and each elimination step updates every lower row at
once with an outer product. The normal equations need no loop either:
`Z∘.*E` raises every speed to every exponent in the table `E`, and `+⌿`
sums over the speeds.

APL's right-to-left rule bites here: `K-1↓⍳N` drops one item before
subtracting, so the code writes `(K-1)↓⍳N`. We skip `⌹`, APL's built-in
matrix divide, which would solve the system in one symbol.
