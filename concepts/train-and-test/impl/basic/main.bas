10 REM Train and test error for polynomials of degree 1 to 8, in classic
20 REM BASIC.
30 REM
40 REM Each polynomial is fitted by least squares to the training drives
50 REM only: we build the normal equations and solve them by Gaussian
60 REM elimination. Then we measure its root-mean-square error on the
70 REM training drives and on the test drives it never saw.
80 REM
90 REM run.sh passes the data path in the DATA environment variable,
100 REM because bwbasic can't read command-line arguments.
110 MAXDEG = 8
120 REM TX, TY hold the training speeds (scaled) and litres; SX, SY the
130 REM test ones. M is the augmented matrix, the equations with their
140 REM right-hand side in column NS + 1, and CF the coefficients.
150 DIM TX(500), TY(500), SX(500), SY(500), FL$(20)
160 DIM M(9, 10), CF(9), PW(17), TR(8), TE(8)
170 GOSUB 1000 : REM read the drives into TX, TY and SX, SY
180 REM Map the training speeds onto -1 to 1. Raw speeds to the 16th
190 REM power (the largest entry at degree 8) would swamp the small ones
200 REM and make the equations hard to solve accurately.
210 LO = TX(1) : HI = TX(1)
220 FOR I = 1 TO NT
230 IF TX(I) < LO THEN LO = TX(I)
240 IF TX(I) > HI THEN HI = TX(I)
250 NEXT I
260 MD = (LO + HI) / 2 : HF = (HI - LO) / 2
270 FOR I = 1 TO NT
280 TX(I) = (TX(I) - MD) / HF
290 NEXT I
300 FOR I = 1 TO NE
310 SX(I) = (SX(I) - MD) / HF
320 NEXT I
330 PRINT "train_count"; NT
340 PRINT "test_count"; NE
350 FOR D = 1 TO MAXDEG
360 GOSUB 2000 : REM build the equations for degree D in M
370 GOSUB 5000 : REM solve them into CF
380 GOSUB 6000 : REM the two errors, into TR(D) and TE(D)
390 NEXT D
400 FOR D = 1 TO MAXDEG
410 L$ = "train_rmse_d" + MID$(STR$(D), 2) : Y = TR(D) : GOSUB 3000
420 NEXT D
430 FOR D = 1 TO MAXDEG
440 L$ = "test_rmse_d" + MID$(STR$(D), 2) : Y = TE(D) : GOSUB 3000
450 NEXT D
460 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read every drive, sorting it into the training or test arrays.
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find which field of the header holds each column
1050 FOR J = 1 TO NF
1060 IF FL$(J) = "speed" THEN CX = J
1070 IF FL$(J) = "litres" THEN CY = J
1080 IF FL$(J) = "split" THEN CS = J
1090 NEXT J
1100 NT = 0 : NE = 0
1110 IF EOF(1) THEN 1190
1120 LINE INPUT #1, L$
1130 GOSUB 4000
1140 X = VAL(FL$(CX)) : Y = VAL(FL$(CY))
1150 IF FL$(CS) = "train" THEN NT = NT + 1 : TX(NT) = X : TY(NT) = Y
1160 IF FL$(CS) <> "train" THEN NE = NE + 1 : SX(NE) = X : SY(NE) = Y
1170 GOTO 1110
1190 CLOSE #1
1200 RETURN
2000 REM Least squares for degree D: the coefficients solve NS equations,
2010 REM where M(I, J) is the sum of z^(I + J - 2) over the training drives
2020 REM and M(I, NS + 1) the sum of y z^(I - 1). (Rows count from 1, so
2030 REM row I is power I - 1.)
2040 NS = D + 1
2050 FOR I = 1 TO NS
2060 FOR J = 1 TO NS + 1
2070 M(I, J) = 0
2080 NEXT J
2090 NEXT I
2100 FOR P = 1 TO NT
2110 REM PW(K) is z^(K - 1), built by multiplying, from z^0 = 1 up.
2120 PW(1) = 1
2130 FOR K = 2 TO 2 * NS - 1
2140 PW(K) = PW(K - 1) * TX(P)
2150 NEXT K
2160 FOR I = 1 TO NS
2170 M(I, NS + 1) = M(I, NS + 1) + TY(P) * PW(I)
2180 FOR J = 1 TO NS
2190 M(I, J) = M(I, J) + PW(I + J - 1)
2200 NEXT J
2210 NEXT I
2220 NEXT P
2230 RETURN
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
5000 REM Solve the NS equations in M by Gaussian elimination with partial
5010 REM pivoting, leaving the answer in CF(1..NS). A FOR loop with an
5020 REM empty range still runs once here, so the loops that can be empty
5030 REM are WHILE loops.
5040 FOR C = 1 TO NS
5050 REM Swap up the row with the largest entry in this column, which
5060 REM keeps the rounding error small.
5070 PV = C
5080 R = C + 1
5090 WHILE R <= NS
5100 IF ABS(M(R, C)) > ABS(M(PV, C)) THEN PV = R
5110 R = R + 1
5120 WEND
5130 FOR J = 1 TO NS + 1
5140 T = M(C, J) : M(C, J) = M(PV, J) : M(PV, J) = T
5150 NEXT J
5160 R = C + 1
5170 WHILE R <= NS
5180 FC = M(R, C) / M(C, C)
5190 FOR J = C TO NS + 1
5200 M(R, J) = M(R, J) - FC * M(C, J)
5210 NEXT J
5220 R = R + 1
5230 WEND
5240 NEXT C
5250 REM Back substitution, from the last unknown up.
5260 FOR R = NS TO 1 STEP -1
5270 T = M(R, NS + 1)
5280 J = R + 1
5290 WHILE J <= NS
5300 T = T - M(R, J) * CF(J)
5310 J = J + 1
5320 WEND
5330 CF(R) = T / M(R, R)
5340 NEXT R
5350 RETURN
6000 REM Root-mean-square error of the fit CF on the training drives, into
6010 REM TR(D), and on the test drives, into TE(D).
6020 T = 0
6030 FOR P = 1 TO NT
6040 Z = TX(P) : GOSUB 7000
6050 T = T + (YH - TY(P)) ^ 2
6060 NEXT P
6070 TR(D) = SQR(T / NT)
6080 T = 0
6090 FOR P = 1 TO NE
6100 Z = SX(P) : GOSUB 7000
6110 T = T + (YH - SY(P)) ^ 2
6120 NEXT P
6130 TE(D) = SQR(T / NE)
6140 RETURN
7000 REM YH = the polynomial CF at Z, by Horner's rule:
7010 REM c1 + z (c2 + z (c3 + ...)).
7020 YH = 0
7030 FOR K = NS TO 1 STEP -1
7040 YH = YH * Z + CF(K)
7050 NEXT K
7060 RETURN
