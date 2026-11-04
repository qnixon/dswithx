10 REM 5-fold cross-validation for k-nearest neighbors, in classic BASIC.
20 REM
30 REM Scores each odd K from 1 to 15 by holding out one fold of 30
40 REM training seeds at a time, picks the K with the best accuracy, and
50 REM then scores that K once on the untouched test seeds.
60 REM
70 REM run.sh passes the data path in the DATA environment variable,
80 REM because bwbasic can't read command-line arguments.
100 NK = 15 : REM the largest K tried
110 DIM TL(500), TW(500), TV$(500) : REM training seeds: length, width, variety
120 DIM QL(500), QW(500), QV$(500) : REM test seeds
130 DIM D(500), U(500), NB(20), CR(20), FL$(20)
140 GOSUB 1000 : REM read the seeds into the two sets
150 PRINT "train_count"; NT
160 PRINT "test_count"; NQ
170 S = INT(NT / 5) : REM fold size; fold F holds rows F*S+1 to (F+1)*S
180 REM Each held-out seed finds its 15 nearest once. The K nearest are
190 REM the first K of those, so every K reuses the same list.
200 FOR H = 1 TO NT
210 HF = INT((H - 1) / S) : PL = TL(H) : PW = TW(H)
220 GOSUB 2000 : REM NB(1..NK), nearest first, from the other folds
230 FOR K = 1 TO NK STEP 2
240 GOSUB 3000 : REM vote among NB(1..K), winner in P$
250 IF P$ = TV$(H) THEN CR(K) = CR(K) + 1
260 NEXT K
270 NEXT H
280 BK = 0 : BA = -1
290 FOR K = 1 TO NK STEP 2
300 A = CR(K) / NT
310 PRINT "cv_accuracy_k"; MID$(STR$(K), 2); " ";
320 PRINT USING "#.######"; A
330 REM A strict > keeps the smaller K on a tie.
340 IF A > BA THEN BK = K : BA = A
350 NEXT K
360 REM Only now touch the test seeds, once, against all training seeds.
370 C = 0 : HF = -1
380 FOR T = 1 TO NQ
390 PL = QL(T) : PW = QW(T)
400 GOSUB 2000
410 K = BK
420 GOSUB 3000
430 IF P$ = QV$(T) THEN C = C + 1
440 NEXT T
450 PRINT "best_k"; BK
460 PRINT "test_correct"; C
470 PRINT "test_accuracy ";
480 PRINT USING "#.######"; C / NQ
490 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read each row into the training set or the test set by its split.
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find which field of the header holds each column
1050 FOR J = 1 TO NF
1060 IF FL$(J) = "length_mm" THEN CL = J
1070 IF FL$(J) = "width_mm" THEN CW = J
1080 IF FL$(J) = "variety" THEN CV = J
1090 IF FL$(J) = "split" THEN CS = J
1100 NEXT J
1110 NT = 0 : NQ = 0
1120 IF EOF(1) THEN 1190
1130 LINE INPUT #1, L$
1140 GOSUB 4000
1150 IF FL$(CS) = "train" THEN GOSUB 1300 ELSE GOSUB 1400
1160 GOTO 1120
1190 CLOSE #1
1200 RETURN
1300 REM Add the row just split to the training set.
1310 NT = NT + 1 : TL(NT) = VAL(FL$(CL)) : TW(NT) = VAL(FL$(CW)) : TV$(NT) = FL$(CV)
1320 RETURN
1400 REM Add the row just split to the test set.
1410 NQ = NQ + 1 : QL(NQ) = VAL(FL$(CL)) : QW(NQ) = VAL(FL$(CW)) : QV$(NQ) = FL$(CV)
1420 RETURN
2000 REM The NK training seeds nearest (PL, PW), skipping fold HF.
2010 REM Seeds in the held-out fold start out marked as used in U.
2020 FOR J = 1 TO NT
2030 D(J) = SQR((PL - TL(J)) ^ 2 + (PW - TW(J)) ^ 2) : U(J) = 0
2040 IF INT((J - 1) / S) = HF THEN U(J) = 1
2050 NEXT J
2060 FOR M = 1 TO NK
2070 B = 0 : BD = 1E+30 : REM BD starts larger than any distance
2080 FOR J = 1 TO NT
2090 REM A strict < keeps the earlier row when two distances are equal.
2100 IF U(J) = 0 AND D(J) < BD THEN B = J : BD = D(J)
2110 NEXT J
2120 NB(M) = B : U(B) = 1
2130 NEXT M
2140 RETURN
3000 REM Count each neighbor's votes; the first to reach the most votes wins.
3010 BV = 0
3020 FOR M = 1 TO K
3030 V = 0
3040 FOR J = 1 TO K
3050 IF TV$(NB(J)) = TV$(NB(M)) THEN V = V + 1
3060 NEXT J
3070 IF V > BV THEN BV = V : P$ = TV$(NB(M))
3080 NEXT M
3090 RETURN
4000 REM Split L$ at its commas into FL$(1) to FL$(NF).
4010 NF = 0 : P = 1
4020 Q = INSTR(P, L$, ",")
4030 NF = NF + 1
4040 IF Q = 0 THEN FL$(NF) = MID$(L$, P) : RETURN
4050 FL$(NF) = MID$(L$, P, Q - P) : P = Q + 1
4060 GOTO 4020
