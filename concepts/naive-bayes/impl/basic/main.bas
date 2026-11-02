10 REM Categorical naive Bayes with add-one (Laplace) smoothing, in
20 REM classic BASIC.
30 REM
40 REM Learns P(label) and P(feature value | label) by counting training
50 REM rows, then labels each test row with the label that has the highest
60 REM log-probability. There are no dictionaries, so nothing is stored:
70 REM each count is found again by scanning the training rows.
80 REM
90 REM run.sh passes the data path in the DATA environment variable.
100 NFE = 3
110 DIM FE$(3), FC(3), DV(3), FL$(20)
120 DIM V$(1000, 3), LB$(1000), SP$(1000), T(1000), LS$(20)
130 FE$(1) = "has_link" : FE$(2) = "mentions_money" : FE$(3) = "known_sender"
140 GOSUB 1000 : REM read rows; T(1) to T(NT) are the training row numbers
150 GOSUB 2000 : REM list the labels LS$(1) to LS$(NL) and count values DV(f)
160 NTE = 0 : CO = 0
170 FOR R = 1 TO N
180 IF SP$(R) <> "test" THEN 220
190 NTE = NTE + 1
200 GOSUB 3000 : REM classify row R into BL$
210 IF BL$ = LB$(R) THEN CO = CO + 1
220 NEXT R
230 PRINT "train_count"; NT
240 PRINT "test_count"; NTE
250 PRINT "correct"; CO
260 PRINT "accuracy ";
270 PRINT USING "#.######"; CO / NTE
280 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read every row: V$(r, f) for each feature, LB$(r), and SP$(r).
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find which field of the header holds each column
1050 FOR C = 1 TO NF
1060 FOR G = 1 TO NFE
1070 IF FL$(C) = FE$(G) THEN FC(G) = C
1080 NEXT G
1090 IF FL$(C) = "label" THEN LCOL = C
1100 IF FL$(C) = "split" THEN SCOL = C
1110 NEXT C
1120 N = 0 : NT = 0
1130 IF EOF(1) THEN 1220
1140 LINE INPUT #1, L$
1150 GOSUB 4000
1160 N = N + 1 : LB$(N) = FL$(LCOL) : SP$(N) = FL$(SCOL)
1170 FOR G = 1 TO NFE
1180 V$(N, G) = FL$(FC(G))
1190 NEXT G
1200 IF SP$(N) = "train" THEN NT = NT + 1 : T(NT) = N
1210 GOTO 1130
1220 CLOSE #1
1230 RETURN
2000 REM A label or value is new if no earlier training row has it.
2010 REM This FOR runs its body once even when the range is empty (FOR E = 1
2020 REM TO 0), so the searches over earlier rows use WHILE, which doesn't.
2030 NL = 0
2040 FOR I = 1 TO NT
2050 S = 0 : E = 1
2060 WHILE E < I
2070 IF LB$(T(E)) = LB$(T(I)) THEN S = 1
2080 E = E + 1
2090 WEND
2100 IF S = 0 THEN NL = NL + 1 : LS$(NL) = LB$(T(I))
2110 FOR G = 1 TO NFE
2120 S = 0 : E = 1
2130 WHILE E < I
2140 IF V$(T(E), G) = V$(T(I), G) THEN S = 1
2150 E = E + 1
2160 WEND
2170 IF S = 0 THEN DV(G) = DV(G) + 1
2180 NEXT G
2190 NEXT I
2200 REM Insertion sort puts the labels in alphabetical order; <= compares
2210 REM text by character code.
2220 I = 2
2230 WHILE I <= NL
2240 Y$ = LS$(I) : J = I - 1
2250 IF J < 1 THEN 2280
2260 IF LS$(J) <= Y$ THEN 2280
2270 LS$(J + 1) = LS$(J) : J = J - 1 : GOTO 2250
2280 LS$(J + 1) = Y$
2290 I = I + 1
2300 WEND
2310 RETURN
3000 REM Classify row R. Labels are tried in alphabetical order, and only
3010 REM a strictly higher score replaces the best, so a tie goes to the first.
3020 FOR K = 1 TO NL
3030 GOSUB 5000 : REM score label LS$(K) for row R into SC
3040 IF K = 1 THEN BL$ = LS$(K) : BS = SC
3050 IF SC > BS THEN BL$ = LS$(K) : BS = SC
3060 NEXT K
3070 RETURN
4000 REM Split L$ at its commas into FL$(1) to FL$(NF).
4010 NF = 0 : P = 1
4020 Q = INSTR(P, L$, ",")
4030 NF = NF + 1
4040 IF Q = 0 THEN FL$(NF) = MID$(L$, P) : RETURN
4050 FL$(NF) = MID$(L$, P, Q - P) : P = Q + 1
4060 GOTO 4020
5000 REM Log-score of label LS$(K) for row R. Logs turn the product of
5010 REM probabilities into a sum, avoiding underflow.
5020 LCN = 0
5030 FOR I = 1 TO NT
5040 IF LB$(T(I)) = LS$(K) THEN LCN = LCN + 1
5050 NEXT I
5060 SC = LOG(LCN / NT)
5070 FOR G = 1 TO NFE
5080 CN = 0
5090 FOR I = 1 TO NT
5100 IF LB$(T(I)) = LS$(K) AND V$(T(I), G) = V$(R, G) THEN CN = CN + 1
5110 NEXT I
5120 REM Add-one smoothing: an unseen value never gets probability zero.
5130 SC = SC + LOG((CN + 1) / (LCN + DV(G)))
5140 NEXT G
5150 RETURN
