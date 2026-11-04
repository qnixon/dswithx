10 REM Evaluation metrics for a binary classifier, in classic BASIC.
20 REM
30 REM Reads each part's true label and the model's score, then reports
40 REM the confusion matrix, accuracy, precision, recall, and F1 at two
50 REM thresholds, the accuracy of never flagging anything, and the area
60 REM under the ROC curve.
70 REM
80 REM run.sh passes the data path in the DATA environment variable,
90 REM because bwbasic can't read command-line arguments.
100 DIM DF(1000), SC(1000), FL$(20) : REM defective (1 or 0) and score
110 GOSUB 1000 : REM read the parts into DF(1..N) and SC(1..N)
120 NP = 0
130 FOR I = 1 TO N
140 NP = NP + DF(I)
150 NEXT I
160 PRINT "parts"; N
170 PRINT "defective"; NP
180 REM Never flagging anything is right about every good part.
190 L$ = "baseline_accuracy" : Y = (N - NP) / N : GOSUB 3000
200 SF$ = "50" : TH = .5 : GOSUB 2000
210 SF$ = "30" : TH = .3 : GOSUB 2000
220 REM AUC: the chance that a random defective part outscores a random
230 REM good one. Compare every pair, scoring 2 for a win and 1 for a tie,
240 REM so the count stays a whole number until the final division.
250 PT = 0
260 FOR I = 1 TO N
270 FOR J = 1 TO N
280 IF DF(I) = 1 AND DF(J) = 0 AND SC(I) > SC(J) THEN PT = PT + 2
290 IF DF(I) = 1 AND DF(J) = 0 AND SC(I) = SC(J) THEN PT = PT + 1
300 NEXT J
310 NEXT I
320 L$ = "auc" : Y = PT / (2 * NP * (N - NP)) : GOSUB 3000
330 SYSTEM : REM without SYSTEM, bwbasic waits at its prompt
1000 REM Read every part's label and score.
1010 F$ = ENVIRON$("DATA")
1020 OPEN "I", #1, F$
1030 LINE INPUT #1, L$
1040 GOSUB 4000 : REM find which field of the header holds each column
1050 FOR J = 1 TO NF
1060 IF FL$(J) = "defective" THEN CD = J
1070 IF FL$(J) = "score" THEN CS = J
1080 NEXT J
1090 N = 0
1100 IF EOF(1) THEN 1150
1110 LINE INPUT #1, L$
1120 GOSUB 4000
1130 N = N + 1 : DF(N) = VAL(FL$(CD)) : SC(N) = VAL(FL$(CS))
1140 GOTO 1100
1150 CLOSE #1
1160 RETURN
2000 REM Count and score the parts at threshold TH, naming lines with SF$.
2010 REM A part is flagged when its score reaches the threshold.
2020 TP = 0 : FP = 0 : FN = 0 : TN = 0
2030 FOR I = 1 TO N
2040 IF SC(I) >= TH AND DF(I) = 1 THEN TP = TP + 1
2050 IF SC(I) >= TH AND DF(I) = 0 THEN FP = FP + 1
2060 IF SC(I) < TH AND DF(I) = 1 THEN FN = FN + 1
2070 IF SC(I) < TH AND DF(I) = 0 THEN TN = TN + 1
2080 NEXT I
2090 PR = TP / (TP + FP) : REM of the flagged parts, how many are defective
2100 RC = TP / (TP + FN) : REM of the defective parts, how many are flagged
2110 PRINT "tp_at_"; SF$; TP
2120 PRINT "fp_at_"; SF$; FP
2130 PRINT "fn_at_"; SF$; FN
2140 PRINT "tn_at_"; SF$; TN
2150 L$ = "accuracy_at_" + SF$ : Y = (TP + TN) / N : GOSUB 3000
2160 L$ = "precision_at_" + SF$ : Y = PR : GOSUB 3000
2170 L$ = "recall_at_" + SF$ : Y = RC : GOSUB 3000
2180 L$ = "f1_at_" + SF$ : Y = 2 * PR * RC / (PR + RC) : GOSUB 3000
2190 RETURN
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
