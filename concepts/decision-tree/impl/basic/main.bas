10 REM A decision tree classifier (CART with Gini impurity), in classic BASIC.
20 REM
30 REM Grows a tree on the training days by always making the split that
40 REM leaves the two sides purest, then predicts rain for the test days.
50 REM GOSUB can call itself, but every variable is global, so a recursive
60 REM grow would lose its place. Instead, nodes wait on a stack: popping
70 REM the left child before the right visits them in preorder, and each
80 REM node is printed as soon as it is decided.
90 REM
100 REM run.sh passes the data path in the DATA environment variable,
110 REM because bwbasic can't read command-line arguments.
120 MAXDEPTH = 3 : MINSIZE = 5
130 DIM NAME$(3), FL$(20)
140 NAME$(1) = "humidity" : NAME$(2) = "pressure" : NAME$(3) = "wind"
150 REM Each day has three features, a label, and DN, the tree node it sits
160 REM in while the tree grows (0 for a test day, so it is never counted).
170 DIM X(1000, 3), RAIN$(1000), ISTRAIN(1000), DN(1000)
180 REM Depth 3 allows at most 15 nodes. A split node has a feature (0 for
190 REM a leaf), a threshold, and two children; a leaf has a prediction.
200 DIM DEPTH(15), FEAT(15), THR(15), LFT(15), RGT(15), PRED$(15), STACK(15)
210 GOSUB 1000 : REM read the days
220 PRINT "train_count"; NTRAIN
230 PRINT "test_count"; NTEST
240 REM Every training day starts in the root, node 1, at depth 0.
250 NODES = 1 : DEPTH(1) = 0
260 FOR I = 1 TO NDAYS
270 IF ISTRAIN(I) THEN DN(I) = 1
280 NEXT I
290 SP = 1 : STACK(1) = 1 : PREORDER = 0 : LEAVES = 0
300 WHILE SP > 0
310 K = STACK(SP) : SP = SP - 1
320 GOSUB 2000 : REM decide node K
330 WEND
340 PRINT "leaves"; LEAVES
350 TRAINOK = 0 : TESTOK = 0
360 FOR I = 1 TO NDAYS
370 GOSUB 8000 : REM predict day I into P$
380 REM A second IF after THEN on the same line is unreliable in bwbasic,
390 REM so both tests go in one IF, joined by AND.
400 IF P$ = RAIN$(I) AND ISTRAIN(I) = 1 THEN TRAINOK = TRAINOK + 1
410 IF P$ = RAIN$(I) AND ISTRAIN(I) = 0 THEN TESTOK = TESTOK + 1
420 NEXT I
430 L$ = "train_accuracy" : Y = TRAINOK / NTRAIN : GOSUB 3000
440 PRINT "correct"; TESTOK
450 L$ = "accuracy" : Y = TESTOK / NTEST : GOSUB 3000
460 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read every day into X, RAIN$, and ISTRAIN, finding the columns
1010 REM by their names in the header.
1020 F$ = ENVIRON$("DATA")
1030 OPEN "I", #1, F$
1040 LINE INPUT #1, L$
1050 GOSUB 4000
1060 DIM COL(3)
1070 FOR C = 1 TO NF
1080 FOR F = 1 TO 3
1090 IF FL$(C) = NAME$(F) THEN COL(F) = C
1100 NEXT F
1110 IF FL$(C) = "rain" THEN RAINCOL = C
1120 IF FL$(C) = "split" THEN SPLITCOL = C
1130 NEXT C
1140 NDAYS = 0 : NTRAIN = 0
1150 IF EOF(1) THEN 1250
1160 LINE INPUT #1, L$
1170 GOSUB 4000
1180 NDAYS = NDAYS + 1
1190 FOR F = 1 TO 3
1200 X(NDAYS, F) = VAL(FL$(COL(F)))
1210 NEXT F
1220 RAIN$(NDAYS) = FL$(RAINCOL)
1230 IF FL$(SPLITCOL) = "train" THEN ISTRAIN(NDAYS) = 1 : NTRAIN = NTRAIN + 1
1240 GOTO 1150
1250 CLOSE #1 : NTEST = NDAYS - NTRAIN
1260 RETURN
2000 REM Decide node K: make it a leaf, or split it and push its two
2010 REM children, right first so the left one is popped next.
2020 PREORDER = PREORDER + 1 : ID$ = "node_" + MID$(STR$(PREORDER), 2)
2030 N = 0 : YES = 0
2040 FOR I = 1 TO NDAYS
2050 IF DN(I) = K THEN N = N + 1
2060 IF DN(I) = K AND RAIN$(I) = "yes" THEN YES = YES + 1
2070 NEXT I
2080 P = YES / N : G = 1 - P * P - (1 - P) * (1 - P)
2090 BEST = 9 : REM higher than any Gini score, so "no split found"
2100 IF G > 0 AND N >= MINSIZE AND DEPTH(K) < MAXDEPTH THEN GOSUB 5000
2110 REM No split was tried, or none makes the sides purer: a leaf.
2120 IF BEST < G THEN 2180
2130 LEAVES = LEAVES + 1
2140 REM An even split predicts "no".
2150 IF YES * 2 > N THEN PRED$(K) = "yes" ELSE PRED$(K) = "no"
2160 PRINT ID$; "_predict "; PRED$(K)
2170 RETURN
2180 FEAT(K) = BESTF : THR(K) = BESTT
2190 PRINT ID$; "_feature "; NAME$(BESTF)
2200 L$ = ID$ + "_threshold" : Y = BESTT : GOSUB 3000
2210 LFT(K) = NODES + 1 : RGT(K) = NODES + 2 : NODES = NODES + 2
2220 DEPTH(LFT(K)) = DEPTH(K) + 1 : DEPTH(RGT(K)) = DEPTH(K) + 1
2230 FOR I = 1 TO NDAYS
2240 IF DN(I) <> K THEN 2260 : REM skip days in other nodes
2250 IF X(I, BESTF) <= BESTT THEN DN(I) = LFT(K) ELSE DN(I) = RGT(K)
2260 NEXT I
2270 SP = SP + 1 : STACK(SP) = RGT(K)
2280 SP = SP + 1 : STACK(SP) = LFT(K)
2290 RETURN
3000 REM Print L$ and Y with six decimals.
3010 PRINT L$; " ";
3020 PRINT USING "#.######"; Y
3030 RETURN
4000 REM Split L$ at its commas into FL$(1) to FL$(NF).
4010 NF = 0 : P = 1
4020 Q = INSTR(P, L$, ",")
4030 NF = NF + 1
4040 IF Q = 0 THEN FL$(NF) = MID$(L$, P) : RETURN
4050 FL$(NF) = MID$(L$, P, Q - P) : P = Q + 1
4060 GOTO 4020
5000 REM The lowest weighted Gini impurity over every feature and threshold
5010 REM for node K, into BEST, BESTF, and BESTT. Features go in column
5020 REM order, thresholds from smallest to largest, and only a strictly
5030 REM lower score replaces the best so far.
5040 FOR F = 1 TO 3
5050 REM Start at the node's smallest value, then step through the
5060 REM distinct values in order without sorting them.
5070 LOW = 1E+30
5080 FOR I = 1 TO NDAYS
5090 IF DN(I) = K AND X(I, F) < LOW THEN LOW = X(I, F)
5100 NEXT I
5110 GOSUB 6000 : REM the next value above LOW, into NXT
5120 WHILE HASNEXT
5130 T = (LOW + NXT) / 2
5140 GOSUB 7000 : REM score the split at T, into S
5150 IF S < BEST THEN BEST = S : BESTF = F : BESTT = T
5160 LOW = NXT
5170 GOSUB 6000
5180 WEND
5190 NEXT F
5200 RETURN
6000 REM The smallest value of feature F in node K above LOW, into NXT,
6010 REM with HASNEXT = 0 if there is none.
6020 HASNEXT = 0
6030 FOR I = 1 TO NDAYS
6040 IF DN(I) <> K THEN 6070
6050 IF X(I, F) <= LOW THEN 6070
6060 IF HASNEXT = 0 OR X(I, F) < NXT THEN NXT = X(I, F) : HASNEXT = 1
6070 NEXT I
6080 RETURN
7000 REM (nL * giniL + nR * giniR) / n for feature F at threshold T, into
7010 REM S. Left is value <= T. Both sides hold at least one day, since T
7020 REM lies between two values present in the node.
7030 NL = 0 : YL = 0
7040 FOR I = 1 TO NDAYS
7050 IF DN(I) <> K OR X(I, F) > T THEN 7080
7060 NL = NL + 1
7070 IF RAIN$(I) = "yes" THEN YL = YL + 1
7080 NEXT I
7090 P = YL / NL : GL = 1 - P * P - (1 - P) * (1 - P)
7100 P = (YES - YL) / (N - NL) : GR = 1 - P * P - (1 - P) * (1 - P)
7110 S = (NL * GL + (N - NL) * GR) / N
7120 RETURN
8000 REM Walk day I down from the root to a leaf, into P$.
8010 K = 1
8020 WHILE FEAT(K) > 0
8030 REM X(I, FEAT(K)) in one step reads the wrong element in bwbasic, so
8040 REM copy FEAT(K) into F first.
8050 F = FEAT(K)
8060 IF X(I, F) <= THR(K) THEN K = LFT(K) ELSE K = RGT(K)
8070 WEND
8080 P$ = PRED$(K)
8090 RETURN
