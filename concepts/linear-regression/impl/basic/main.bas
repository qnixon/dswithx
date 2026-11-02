10 REM Simple linear regression by least squares, in classic BASIC.
20 REM
30 REM Fits score = intercept + slope * hours. There is no regression or
40 REM correlation function, so the sums are written out as loops.
50 REM
60 REM run.sh passes the data path in the DATA environment variable,
70 REM because bwbasic can't read command-line arguments.
100 DIM X(1000), Y(1000), FL$(20) : REM arrays have a fixed size, set by DIM
110 GOSUB 1000 : REM read hours into X(1..N) and score into Y(1..N)
120 REM First pass: the means.
130 SX = 0 : SY = 0
140 FOR I = 1 TO N
150 SX = SX + X(I) : SY = SY + Y(I)
160 NEXT I
170 MX = SX / N : MY = SY / N
180 REM Second pass: sums of squared deviations and of cross-products.
190 XX = 0 : YY = 0 : XY = 0
200 FOR I = 1 TO N
210 DX = X(I) - MX : DY = Y(I) - MY
220 XX = XX + DX * DX : YY = YY + DY * DY : XY = XY + DX * DY
230 NEXT I
240 B = XY / XX
250 A = MY - B * MX
260 R = XY / SQR(XX * YY)
270 PRINT "count"; N
280 L$ = "slope" : V = B : GOSUB 3000
290 L$ = "intercept" : V = A : GOSUB 3000
300 L$ = "r" : V = R : GOSUB 3000
310 L$ = "r_squared" : V = R * R : GOSUB 3000
320 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read the hours and score columns into X(1..N) and Y(1..N).
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find which fields of the header hold each column
1050 FOR K = 1 TO NF
1060 IF FL$(K) = "hours" THEN CX = K
1070 IF FL$(K) = "score" THEN CY = K
1080 NEXT K
1090 N = 0
1100 IF EOF(1) THEN 1150
1110 LINE INPUT #1, L$
1120 GOSUB 4000
1130 N = N + 1 : X(N) = VAL(FL$(CX)) : Y(N) = VAL(FL$(CY))
1140 GOTO 1100
1150 CLOSE #1
1160 RETURN
3000 REM Print L$ and V with six decimals.
3010 PRINT L$; " ";
3020 PRINT USING "#.######"; V
3030 RETURN
4000 REM Split L$ at its commas into FL$(1) to FL$(NF).
4010 NF = 0 : P = 1
4020 Q = INSTR(P, L$, ",")
4030 NF = NF + 1
4040 IF Q = 0 THEN FL$(NF) = MID$(L$, P) : RETURN
4050 FL$(NF) = MID$(L$, P, Q - P) : P = Q + 1
4060 GOTO 4020
