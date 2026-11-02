10 REM Principal component analysis by power iteration, in classic BASIC.
20 REM
30 REM Standardizes the four scores, builds their correlation matrix, and
40 REM finds the top two eigenvectors (the principal components): power
50 REM iteration finds the first, then deflation removes it from the
60 REM matrix so the same steps find the second.
70 REM
80 REM run.sh passes the data path in the DATA environment variable,
90 REM because bwbasic can't read command-line arguments.
100 K = 4 : STEPS = 1000
110 REM PC(1, J) and PC(2, J) hold the two components; EV(1), EV(2) their
120 REM eigenvalues. M is the matrix that power iteration works on.
130 DIM SUBJ$(4), COL(4), Z(200, 4), C(4, 4), M(4, 4), V(4), MV(4)
140 DIM PC(2, 4), EV(2), FL$(20)
150 SUBJ$(1) = "math" : SUBJ$(2) = "physics"
160 SUBJ$(3) = "reading" : SUBJ$(4) = "writing"
170 GOSUB 1000 : REM read the four columns into Z(1..N, 1..4)
180 GOSUB 2000 : REM standardize them and fill the correlation matrix C
190 FOR A = 1 TO K
200 FOR B = 1 TO K
210 M(A, B) = C(A, B)
220 NEXT B
230 NEXT A
240 CI = 1 : GOSUB 5000 : REM power iteration on M fills PC(1, ...) and EV(1)
250 REM Deflation: subtract the first component's share, leaving the rest.
260 FOR A = 1 TO K
270 FOR B = 1 TO K
280 M(A, B) = C(A, B) - EV(1) * PC(1, A) * PC(1, B)
290 NEXT B
300 NEXT A
310 CI = 2 : GOSUB 5000
320 PRINT "count"; N
330 CI = 1 : GOSUB 6000 : REM print the first component
340 CI = 2 : GOSUB 6000
350 REM The first student's scores, projected onto each component.
360 S1 = 0 : S2 = 0
370 FOR A = 1 TO K
380 S1 = S1 + Z(1, A) * PC(1, A) : S2 = S2 + Z(1, A) * PC(2, A)
390 NEXT A
400 L$ = "student_1_pc1" : Y = S1 : GOSUB 3000
410 L$ = "student_1_pc2" : Y = S2 : GOSUB 3000
420 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read the columns named in SUBJ$ into Z(1..N, 1..4).
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find each subject's position in the header
1050 FOR J = 1 TO K
1060 FOR I = 1 TO NF
1070 IF FL$(I) = SUBJ$(J) THEN COL(J) = I
1080 NEXT I
1090 NEXT J
1100 N = 0
1110 IF EOF(1) THEN 1190
1120 LINE INPUT #1, L$
1130 GOSUB 4000
1140 N = N + 1
1150 FOR J = 1 TO K
1160 Z(N, J) = VAL(FL$(COL(J)))
1170 NEXT J
1180 GOTO 1110
1190 CLOSE #1
1200 RETURN
2000 REM Standardize each column to mean 0 and (sample) standard deviation
2010 REM 1, then fill C, the correlation matrix: their covariance.
2020 FOR J = 1 TO K
2030 T = 0
2040 FOR I = 1 TO N
2050 T = T + Z(I, J)
2060 NEXT I
2070 MU = T / N : T = 0
2080 FOR I = 1 TO N
2090 T = T + (Z(I, J) - MU) ^ 2
2100 NEXT I
2110 SD = SQR(T / (N - 1))
2120 FOR I = 1 TO N
2130 Z(I, J) = (Z(I, J) - MU) / SD
2140 NEXT I
2150 NEXT J
2160 FOR A = 1 TO K
2170 FOR B = 1 TO K
2180 T = 0
2190 FOR I = 1 TO N
2200 T = T + Z(I, A) * Z(I, B)
2210 NEXT I
2220 C(A, B) = T / (N - 1)
2230 NEXT B
2240 NEXT A
2250 RETURN
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
5000 REM Power iteration: multiply V by M and rescale it, STEPS times.
5010 REM Stores V in PC(CI, ...) and its eigenvalue in EV(CI).
5020 V(1) = 1 : V(2) = 0 : V(3) = 0 : V(4) = 0
5030 FOR S = 1 TO STEPS
5040 GOSUB 7000 : REM MV = M times V
5050 T = 0
5060 FOR A = 1 TO K
5070 T = T + MV(A) ^ 2
5080 NEXT A
5090 T = SQR(T)
5100 FOR A = 1 TO K
5110 V(A) = MV(A) / T
5120 NEXT A
5130 NEXT S
5140 REM An eigenvector can point either way; make its first entry positive.
5150 IF V(1) >= 0 THEN 5190
5160 FOR A = 1 TO K
5170 V(A) = -V(A)
5180 NEXT A
5190 GOSUB 7000
5200 EV(CI) = 0 : REM the Rayleigh quotient V . (M V)
5210 FOR A = 1 TO K
5220 EV(CI) = EV(CI) + V(A) * MV(A) : PC(CI, A) = V(A)
5230 NEXT A
5240 RETURN
6000 REM Print component CI: its eigenvalue, share, and loadings.
6010 REM STR$ puts a space before the digits, so MID$ starts at the 2nd.
6020 D$ = MID$(STR$(CI), 2)
6030 L$ = "eigenvalue_" + D$ : Y = EV(CI) : GOSUB 3000
6040 REM Standardized columns each have variance 1, so the total is K.
6050 L$ = "explained_" + D$ : Y = EV(CI) / K : GOSUB 3000
6060 FOR J = 1 TO K
6070 L$ = "pc" + D$ + "_" + SUBJ$(J) : Y = PC(CI, J) : GOSUB 3000
6080 NEXT J
6090 RETURN
7000 REM MV = M times V.
7010 FOR A = 1 TO K
7020 MV(A) = 0
7030 FOR B = 1 TO K
7040 MV(A) = MV(A) + M(A, B) * V(B)
7050 NEXT B
7060 NEXT A
7070 RETURN
