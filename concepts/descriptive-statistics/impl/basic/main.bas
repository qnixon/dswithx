10 REM Descriptive statistics on one CSV column, in classic BASIC.
20 REM
30 REM There are no functions for sum, mean, median, variance, or sorting,
40 REM so each is written out. Subroutines are blocks of numbered lines
50 REM reached with GOSUB, and every variable is global.
60 REM
70 REM run.sh passes the data path in the DATA environment variable,
80 REM because bwbasic can't read command-line arguments.
100 COL$ = "minutes"
110 DIM X(1000), FL$(20) : REM arrays have a fixed size, set by DIM
120 GOSUB 1000 : REM read the column into X(1) to X(N)
130 GOSUB 2000 : REM sort it
140 T = 0
150 FOR I = 1 TO N
160 T = T + X(I)
170 NEXT I
180 M = T / N
190 REM Sample variance divides by N - 1, not N (Bessel's correction).
200 S = 0
210 FOR I = 1 TO N
220 S = S + (X(I) - M) ^ 2
230 NEXT I
240 V = S / (N - 1)
250 IF N MOD 2 = 1 THEN MED = X((N + 1) / 2) ELSE MED = (X(N / 2) + X(N / 2 + 1)) / 2
260 PRINT "count"; N
270 L$ = "sum" : Y = T : GOSUB 3000
280 L$ = "mean" : Y = M : GOSUB 3000
290 L$ = "median" : Y = MED : GOSUB 3000
300 L$ = "min" : Y = X(1) : GOSUB 3000
310 L$ = "max" : Y = X(N) : GOSUB 3000
320 L$ = "range" : Y = X(N) - X(1) : GOSUB 3000
330 L$ = "variance" : Y = V : GOSUB 3000
340 L$ = "std_dev" : Y = SQR(V) : GOSUB 3000
350 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read the column named COL$ into X(1) to X(N).
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find which field of the header is COL$
1050 FOR K = 1 TO NF
1060 IF FL$(K) = COL$ THEN C = K
1070 NEXT K
1080 N = 0
1090 IF EOF(1) THEN 1140
1100 LINE INPUT #1, L$
1110 GOSUB 4000
1120 N = N + 1 : X(N) = VAL(FL$(C))
1130 GOTO 1090
1140 CLOSE #1
1150 RETURN
2000 REM Insertion sort: slide each value left past the larger ones.
2010 FOR I = 2 TO N
2020 Y = X(I) : J = I - 1
2030 IF J < 1 THEN 2060
2040 IF X(J) <= Y THEN 2060
2050 X(J + 1) = X(J) : J = J - 1 : GOTO 2030
2060 X(J + 1) = Y
2070 NEXT I
2080 RETURN
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
