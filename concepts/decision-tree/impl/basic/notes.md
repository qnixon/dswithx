This grows the tree without recursion. `GOSUB` can call itself, but when
we tried it, every level shared the same variables, so nodes wait on a
stack instead. We pop a node, decide it, print it, and push its right child
before its left, which visits the nodes in preorder. The tree lives in
parallel arrays (`FEAT`, `THR`, `LFT`, `RGT`, and `PRED$`), and each
training day records the node it sits in, `DN`.

There's no sort, so subroutine 6000 scans for the next distinct value
above the current one. Two bwbasic surprises shaped the code: an `IF`
after `THEN` ignores its own test, and `X(I, FEAT(K))` reads the wrong
element, so line 8050 copies `FEAT(K)` into `F` first.
