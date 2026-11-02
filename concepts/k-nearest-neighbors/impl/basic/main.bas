10 REM k-nearest neighbors classification, in classic BASIC.
20 REM
30 REM Each test seed gets the majority variety among its K nearest
40 REM training seeds, by Euclidean distance. There is no sort, so we pick
50 REM the nearest unused training seed K times over.
60 REM
70 REM run.sh passes the data path in the DATA environment variable,
80 REM because bwbasic can't read command-line arguments.
100 K = 5
110 DIM TL(500), TW(500), TV$(500) : REM training seeds: length, width, variety
120 DIM QL(500), QW(500), QV$(500) : REM test seeds
130 DIM D(500), U(500), NB(10), FL$(20)
140 GOSUB 1000 : REM read the seeds into the two sets
150 C = 0
160 FOR T = 1 TO NQ
170 GOSUB 2000 : REM find the K nearest training seeds, NB(1..K)
180 GOSUB 3000 : REM vote, leaving the winning variety in P$
190 IF P$ = QV$(T) THEN C = C + 1
200 NEXT T
210 PRINT "train_count"; NT
220 PRINT "test_count"; NQ
230 PRINT "correct"; C
240 PRINT "accuracy ";
250 PRINT USING "#.######"; C / NQ
260 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
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
2000 REM Distances from test seed T, then pick the nearest unused seed K times.
2010 FOR J = 1 TO NT
2020 D(J) = SQR((QL(T) - TL(J)) ^ 2 + (QW(T) - TW(J)) ^ 2) : U(J) = 0
2030 NEXT J
2040 FOR M = 1 TO K
2050 B = 0 : BD = 1E+30 : REM BD starts larger than any distance
2060 FOR J = 1 TO NT
2070 REM A strict < keeps the earlier row when two distances are equal.
2080 IF U(J) = 0 AND D(J) < BD THEN B = J : BD = D(J)
2090 NEXT J
2100 NB(M) = B : U(B) = 1
2110 NEXT M
2120 RETURN
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
