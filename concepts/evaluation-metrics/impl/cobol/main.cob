      *> Evaluation metrics for a binary classifier, in COBOL.
      *>
      *> Reads each part's true label and the model's score, then
      *> reports the confusion matrix, accuracy, precision, recall, and
      *> F1 at two thresholds, the accuracy of never flagging anything,
      *> and the area under the ROC curve.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVALUATION-METRICS.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DATA-FILE ASSIGN TO DYNAMIC WS-FILE-NAME
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  DATA-FILE.
       01  DATA-LINE                PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-FILE-NAME             PIC X(256).
       01  WS-EOF                   PIC X VALUE "N".
           88  END-OF-FILE          VALUE "Y".
       01  WS-LABEL-TEXT            PIC X(40).
       01  WS-SCORE-TEXT            PIC X(40).

      *> Every part's label and score, in file order. Scores have three
      *> decimals, so we keep them as whole thousandths: 0.174 is 174.
      *> Every comparison below is between exact integers.
       01  WS-PART-COUNT            PIC 9(4) VALUE 0.
       01  WS-DEFECTIVE-COUNT       PIC 9(4) VALUE 0.
       01  WS-PARTS.
           05  WS-PART              OCCURS 1000 TIMES.
               10  WS-DEFECTIVE     PIC 9.
               10  WS-SCORE         PIC 9(4).

      *> The threshold being reported, also in thousandths, and the
      *> name suffix that goes with it.
       01  WS-THRESHOLD             PIC 9(4).
       01  WS-SUFFIX                PIC XX.
       01  WS-TP                    PIC 9(4).
       01  WS-FP                    PIC 9(4).
       01  WS-FN                    PIC 9(4).
       01  WS-TN                    PIC 9(4).
       01  WS-PRECISION             PIC 9V9(15).
       01  WS-RECALL                PIC 9V9(15).

       01  WS-POINTS                PIC 9(9) VALUE 0.
       01  WS-PAIRS                 PIC 9(9) VALUE 0.

       01  I                        PIC 9(4).
       01  J                        PIC 9(4).
       01  WS-RESULT                PIC S9(9)V9(12).
       01  WS-RESULT-OUT            PIC -(9)9.9(6).
       01  WS-COUNT-OUT             PIC Z(8)9.

       PROCEDURE DIVISION.
       MAIN.
           ACCEPT WS-FILE-NAME FROM ARGUMENT-VALUE
           OPEN INPUT DATA-FILE
      *>   The first line is the header, defective,score; skip it.
           READ DATA-FILE
               AT END SET END-OF-FILE TO TRUE
           END-READ
           PERFORM UNTIL END-OF-FILE
               READ DATA-FILE
                   AT END SET END-OF-FILE TO TRUE
                   NOT AT END PERFORM ADD-PART
               END-READ
           END-PERFORM
           CLOSE DATA-FILE

           MOVE WS-PART-COUNT TO WS-COUNT-OUT
           DISPLAY "parts " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-DEFECTIVE-COUNT TO WS-COUNT-OUT
           DISPLAY "defective " FUNCTION TRIM(WS-COUNT-OUT)
      *>   Never flagging anything is right about every good part.
           COMPUTE WS-RESULT ROUNDED =
               (WS-PART-COUNT - WS-DEFECTIVE-COUNT) / WS-PART-COUNT
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY "baseline_accuracy " FUNCTION TRIM(WS-RESULT-OUT)

           MOVE 500 TO WS-THRESHOLD
           MOVE "50" TO WS-SUFFIX
           PERFORM REPORT-THRESHOLD
           MOVE 300 TO WS-THRESHOLD
           MOVE "30" TO WS-SUFFIX
           PERFORM REPORT-THRESHOLD

           PERFORM AREA-UNDER-CURVE
           STOP RUN.

      *> Store one defective,score line.
       ADD-PART.
           MOVE SPACES TO WS-LABEL-TEXT WS-SCORE-TEXT
           UNSTRING DATA-LINE DELIMITED BY ","
               INTO WS-LABEL-TEXT WS-SCORE-TEXT
           END-UNSTRING
           IF WS-LABEL-TEXT = SPACES
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-PART-COUNT
           COMPUTE WS-DEFECTIVE(WS-PART-COUNT) =
               FUNCTION NUMVAL(WS-LABEL-TEXT)
      *>   NUMVAL reads "0.174" as 0.174; times 1000 is exactly 174.
           COMPUTE WS-SCORE(WS-PART-COUNT) =
               FUNCTION NUMVAL(WS-SCORE-TEXT) * 1000
           ADD WS-DEFECTIVE(WS-PART-COUNT) TO WS-DEFECTIVE-COUNT.

      *> Sort every part into one of four counts at WS-THRESHOLD, then
      *> print the counts and the ratios built from them. A part is
      *> flagged when its score reaches the threshold.
       REPORT-THRESHOLD.
           MOVE 0 TO WS-TP WS-FP WS-FN WS-TN
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-PART-COUNT
               EVALUATE WS-SCORE(I) >= WS-THRESHOLD
                       ALSO WS-DEFECTIVE(I) = 1
                   WHEN TRUE  ALSO TRUE  ADD 1 TO WS-TP
                   WHEN TRUE  ALSO FALSE ADD 1 TO WS-FP
                   WHEN FALSE ALSO TRUE  ADD 1 TO WS-FN
                   WHEN FALSE ALSO FALSE ADD 1 TO WS-TN
               END-EVALUATE
           END-PERFORM

           MOVE WS-TP TO WS-COUNT-OUT
           DISPLAY "tp_at_" WS-SUFFIX " " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-FP TO WS-COUNT-OUT
           DISPLAY "fp_at_" WS-SUFFIX " " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-FN TO WS-COUNT-OUT
           DISPLAY "fn_at_" WS-SUFFIX " " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-TN TO WS-COUNT-OUT
           DISPLAY "tn_at_" WS-SUFFIX " " FUNCTION TRIM(WS-COUNT-OUT)

           COMPUTE WS-RESULT ROUNDED = (WS-TP + WS-TN) / WS-PART-COUNT
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY "accuracy_at_" WS-SUFFIX " "
               FUNCTION TRIM(WS-RESULT-OUT)
      *>   Precision: of the flagged parts, how many are defective.
      *>   Recall: of the defective parts, how many are flagged.
           COMPUTE WS-PRECISION ROUNDED = WS-TP / (WS-TP + WS-FP)
           COMPUTE WS-RECALL ROUNDED = WS-TP / (WS-TP + WS-FN)
           COMPUTE WS-RESULT-OUT ROUNDED = WS-PRECISION
           DISPLAY "precision_at_" WS-SUFFIX " "
               FUNCTION TRIM(WS-RESULT-OUT)
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RECALL
           DISPLAY "recall_at_" WS-SUFFIX " "
               FUNCTION TRIM(WS-RESULT-OUT)
           COMPUTE WS-RESULT ROUNDED = 2 * WS-PRECISION * WS-RECALL
               / (WS-PRECISION + WS-RECALL)
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY "f1_at_" WS-SUFFIX " " FUNCTION TRIM(WS-RESULT-OUT).

      *> The chance that a random defective part outscores a random
      *> good one. Compare every pair, scoring 2 for a win and 1 for a
      *> tie, so the count stays a whole number until the final
      *> division.
       AREA-UNDER-CURVE.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-PART-COUNT
               IF WS-DEFECTIVE(I) = 1
                   PERFORM VARYING J FROM 1 BY 1
                           UNTIL J > WS-PART-COUNT
                       IF WS-DEFECTIVE(J) = 0
                           ADD 1 TO WS-PAIRS
                           EVALUATE TRUE
                               WHEN WS-SCORE(I) > WS-SCORE(J)
                                   ADD 2 TO WS-POINTS
                               WHEN WS-SCORE(I) = WS-SCORE(J)
                                   ADD 1 TO WS-POINTS
                           END-EVALUATE
                       END-IF
                   END-PERFORM
               END-IF
           END-PERFORM
           COMPUTE WS-RESULT ROUNDED = WS-POINTS / (2 * WS-PAIRS)
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY "auc " FUNCTION TRIM(WS-RESULT-OUT).
