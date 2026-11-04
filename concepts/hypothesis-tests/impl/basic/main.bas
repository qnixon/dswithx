10 REM Exact two-sided permutation test for a difference in means, in
20 REM classic BASIC.
30 REM
40 REM If compost made no difference, the group labels are arbitrary, and
50 REM any K of the N plants could have carried the compost label. We try
60 REM every one of those splits and count how many give a difference at
70 REM least as large as the one we observed. That fraction is the p-value.
80 REM
90 REM run.sh passes the data path in the DATA environment variable,
100 REM because bwbasic can't read command-line arguments.
110 DIM G(100), IX(100), FL$(20) : REM grams per plant, chosen positions
120 GOSUB 1000 : REM read the plants into G(1..N), group sums SA and SB
130 K = NB : REM both groups have K plants
140 T = SA + SB
150 REM Both groups have K plants, so comparing totals is the same as
160 REM comparing means, and totals stay whole numbers: no near-ties.
170 OB = ABS(SB - SA)
180 REM IX(1..K) holds the chosen positions in increasing order. It starts
190 REM at 1, 2, ..., K and steps through every choice in dictionary order.
200 FOR J = 1 TO K
210 IX(J) = J
220 NEXT J
230 SP = 0 : AE = 0
240 R = 0
250 FOR J = 1 TO K
260 R = R + G(IX(J))
270 NEXT J
280 SP = SP + 1
290 REM Two-sided: ABS counts a difference in either direction.
300 IF ABS(R - (T - R)) >= OB THEN AE = AE + 1
310 REM Find the rightmost position that can still move up. Position J can
320 REM go as high as N - K + J, leaving room for the ones after it.
330 J = K
340 IF J < 1 THEN 400
350 IF IX(J) < N - K + J THEN 360
355 J = J - 1 : GOTO 340
360 IX(J) = IX(J) + 1
365 REM Refill the positions after J in a run. bwbasic runs a FOR body at
370 REM least once, even FOR M = 4 TO 3, so skip the loop when J = K.
375 IF J = K THEN 240
380 FOR M = J + 1 TO K
385 IX(M) = IX(M - 1) + 1
390 NEXT M
395 GOTO 240
400 PRINT "control_count"; NA
410 PRINT "compost_count"; NB
420 L$ = "control_mean" : Y = SA / NA : GOSUB 3000
430 L$ = "compost_mean" : Y = SB / NB : GOSUB 3000
440 L$ = "observed_difference" : Y = (SB - SA) / K : GOSUB 3000
450 PRINT "splits"; SP
460 PRINT "as_extreme"; AE
470 L$ = "p_value" : Y = AE / SP : GOSUB 3000
480 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read every plant into G, and total each group as we go.
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find which field of the header holds each column
1050 FOR J = 1 TO NF
1060 IF FL$(J) = "group" THEN CG = J
1070 IF FL$(J) = "grams" THEN CM = J
1080 NEXT J
1090 N = 0 : NA = 0 : NB = 0 : SA = 0 : SB = 0
1100 IF EOF(1) THEN 1190
1110 LINE INPUT #1, L$
1120 GOSUB 4000
1130 N = N + 1 : G(N) = VAL(FL$(CM))
1140 IF FL$(CG) = "control" THEN NA = NA + 1 : SA = SA + G(N)
1150 IF FL$(CG) = "compost" THEN NB = NB + 1 : SB = SB + G(N)
1160 GOTO 1100
1190 CLOSE #1
1200 RETURN
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
