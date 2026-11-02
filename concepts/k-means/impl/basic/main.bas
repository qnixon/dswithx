10 REM k-means clustering (Lloyd's algorithm), in classic BASIC.
20 REM
30 REM Starts from the first K points as centroids, then alternates two
40 REM steps until no point changes cluster: assign each point to its
50 REM nearest centroid, and move each centroid to the mean of its points.
60 REM
70 REM run.sh passes the data path in the DATA environment variable,
80 REM because bwbasic can't read command-line arguments.
100 K = 3 : MAXIT = 100
110 DIM X(1000), Y(1000), A(1000), FL$(20)
120 DIM CX(3), CY(3), SX(3), SY(3), SZ(3)
130 GOSUB 1000 : REM read the points into X(1) to X(N) and Y(1) to Y(N)
140 FOR J = 1 TO K
150 CX(J) = X(J) : CY(J) = Y(J) : REM copy the first K points
160 NEXT J
170 REM 0 means "no cluster yet", so the first pass always counts as a change.
180 FOR I = 1 TO N
190 A(I) = 0
200 NEXT I
210 IT = 0
220 IF IT >= MAXIT THEN 300
230 IT = IT + 1
240 GOSUB 2000 : REM assign each point; CH = 1 if any point moved
250 IF CH = 0 THEN 300
260 GOSUB 3000 : REM move each centroid to the mean of its points
270 GOTO 220
300 REM Count each cluster and add up the squared distances (inertia).
310 FOR J = 1 TO K
320 SZ(J) = 0
330 NEXT J
340 W = 0
350 FOR I = 1 TO N
360 J = A(I) : SZ(J) = SZ(J) + 1
370 W = W + (X(I) - CX(J)) ^ 2 + (Y(I) - CY(J)) ^ 2
380 NEXT I
390 PRINT "iterations"; IT
400 FOR J = 1 TO K
410 J$ = MID$(STR$(J), 2) : REM STR$ puts a space before the number
420 PRINT "centroid_"; J$; "_x ";
430 PRINT USING "#.######"; CX(J)
440 PRINT "centroid_"; J$; "_y ";
450 PRINT USING "#.######"; CY(J)
460 NEXT J
470 FOR J = 1 TO K
480 PRINT "size_"; MID$(STR$(J), 2); SZ(J)
490 NEXT J
500 PRINT "inertia ";
510 PRINT USING "#.######"; W
520 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read the x and y columns into X(1) to X(N) and Y(1) to Y(N).
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find which fields of the header are x and y
1050 FOR C = 1 TO NF
1060 IF FL$(C) = "x" THEN CXI = C
1070 IF FL$(C) = "y" THEN CYI = C
1080 NEXT C
1090 N = 0
1100 IF EOF(1) THEN 1150
1110 LINE INPUT #1, L$
1120 GOSUB 4000
1130 N = N + 1 : X(N) = VAL(FL$(CXI)) : Y(N) = VAL(FL$(CYI))
1140 GOTO 1100
1150 CLOSE #1
1160 RETURN
2000 REM Assign each point to its nearest centroid. Squared distance ranks
2010 REM centroids the same way as distance, so no SQR is needed, and only
2020 REM a strictly smaller distance wins, so a tie goes to the lower index.
2030 CH = 0
2040 FOR I = 1 TO N
2050 B = 1 : BD = (X(I) - CX(1)) ^ 2 + (Y(I) - CY(1)) ^ 2
2060 FOR J = 2 TO K
2070 D = (X(I) - CX(J)) ^ 2 + (Y(I) - CY(J)) ^ 2
2080 IF D < BD THEN B = J : BD = D
2090 NEXT J
2100 IF B <> A(I) THEN A(I) = B : CH = 1
2110 NEXT I
2120 RETURN
3000 REM Sum each cluster's points in one pass, then divide by its size.
3010 FOR J = 1 TO K
3020 SX(J) = 0 : SY(J) = 0 : SZ(J) = 0
3030 NEXT J
3040 FOR I = 1 TO N
3050 J = A(I)
3060 SX(J) = SX(J) + X(I) : SY(J) = SY(J) + Y(I) : SZ(J) = SZ(J) + 1
3070 NEXT I
3080 FOR J = 1 TO K
3090 REM An empty cluster keeps its old centroid.
3100 IF SZ(J) > 0 THEN CX(J) = SX(J) / SZ(J) : CY(J) = SY(J) / SZ(J)
3110 NEXT J
3120 RETURN
4000 REM Split L$ at its commas into FL$(1) to FL$(NF).
4010 NF = 0 : P = 1
4020 Q = INSTR(P, L$, ",")
4030 NF = NF + 1
4040 IF Q = 0 THEN FL$(NF) = MID$(L$, P) : RETURN
4050 FL$(NF) = MID$(L$, P, Q - P) : P = Q + 1
4060 GOTO 4020
