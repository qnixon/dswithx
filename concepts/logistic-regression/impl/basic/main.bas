10 REM Logistic regression by gradient descent, in classic BASIC.
20 REM
30 REM Predicts whether a student passed from study hours and sleep. Each
40 REM feature is rescaled with the training rows' mean and standard
50 REM deviation, then the weights start at zero and take 1000 steps of
60 REM batch gradient descent on the average log-loss.
70 REM
80 REM run.sh passes the data path in the DATA environment variable,
90 REM because bwbasic can't read command-line arguments.
100 RATE = 0.5 : STEPS = 1000
110 REM A holds training rows and B test rows; column 1 is hours, 2 sleep.
120 DIM A(200, 2), YA(200), B(200, 2), YB(200), FL$(20)
130 REM DEF FN makes a one-line function; it reads the global weights.
140 DEF FNP(X1, X2) = 1 / (1 + EXP(-(W0 + W1 * X1 + W2 * X2)))
150 GOSUB 1000 : REM read the CSV into A, YA, B, and YB
160 J = 1 : GOSUB 2000 : REM scale hours
170 J = 2 : GOSUB 2000 : REM scale sleep
180 W0 = 0 : W1 = 0 : W2 = 0
190 FOR S = 1 TO STEPS
200 REM Gradient of the average log-loss: the mean of (p - y) times each
210 REM input, summed over every student before any weight moves.
220 G0 = 0 : G1 = 0 : G2 = 0
230 FOR I = 1 TO NA
240 E = FNP(A(I, 1), A(I, 2)) - YA(I)
250 G0 = G0 + E : G1 = G1 + E * A(I, 1) : G2 = G2 + E * A(I, 2)
260 NEXT I
270 W0 = W0 - RATE * G0 / NA : W1 = W1 - RATE * G1 / NA : W2 = W2 - RATE * G2 / NA
280 NEXT S
290 LOSS = 0
300 FOR I = 1 TO NA
310 P = FNP(A(I, 1), A(I, 2))
320 IF YA(I) = 1 THEN LOSS = LOSS - LOG(P) ELSE LOSS = LOSS - LOG(1 - P)
330 NEXT I
340 LOSS = LOSS / NA
350 HITS = 0
360 FOR I = 1 TO NB
370 IF FNP(B(I, 1), B(I, 2)) >= 0.5 THEN GUESS = 1 ELSE GUESS = 0
380 IF GUESS = YB(I) THEN HITS = HITS + 1
390 NEXT I
400 PRINT "train_count"; NA
410 PRINT "test_count"; NB
420 L$ = "intercept" : Y = W0 : GOSUB 3000
430 L$ = "weight_hours" : Y = W1 : GOSUB 3000
440 L$ = "weight_sleep" : Y = W2 : GOSUB 3000
450 L$ = "log_loss" : Y = LOSS : GOSUB 3000
460 PRINT "correct"; HITS
470 L$ = "accuracy" : Y = HITS / NB : GOSUB 3000
480 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read the CSV into training rows (A, YA) and test rows (B, YB).
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find each column's position in the header
1050 FOR K = 1 TO NF
1060 IF FL$(K) = "hours" THEN CH = K
1070 IF FL$(K) = "sleep" THEN CS = K
1080 IF FL$(K) = "passed" THEN CP = K
1090 IF FL$(K) = "split" THEN CT = K
1100 NEXT K
1110 NA = 0 : NB = 0
1120 IF EOF(1) THEN 1200
1130 LINE INPUT #1, L$
1140 GOSUB 4000
1150 IF FL$(CT) <> "train" THEN 1180
1160 NA = NA + 1 : A(NA, 1) = VAL(FL$(CH)) : A(NA, 2) = VAL(FL$(CS)) : YA(NA) = VAL(FL$(CP))
1170 GOTO 1120
1180 NB = NB + 1 : B(NB, 1) = VAL(FL$(CH)) : B(NB, 2) = VAL(FL$(CS)) : YB(NB) = VAL(FL$(CP))
1190 GOTO 1120
1200 CLOSE #1
1210 RETURN
2000 REM Scale column J to mean 0 and (sample) standard deviation 1,
2010 REM using the training rows only, then shift the test rows the same way.
2020 T = 0
2030 FOR I = 1 TO NA
2040 T = T + A(I, J)
2050 NEXT I
2060 M = T / NA : T = 0
2070 FOR I = 1 TO NA
2080 T = T + (A(I, J) - M) ^ 2
2090 NEXT I
2100 SD = SQR(T / (NA - 1))
2110 FOR I = 1 TO NA
2120 A(I, J) = (A(I, J) - M) / SD
2130 NEXT I
2140 FOR I = 1 TO NB
2150 B(I, J) = (B(I, J) - M) / SD
2160 NEXT I
2170 RETURN
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
