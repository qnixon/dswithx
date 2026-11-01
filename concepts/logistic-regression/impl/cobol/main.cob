      *> Logistic regression by gradient descent, in COBOL.
      *>
      *> Predicts whether a student passed from study hours and sleep.
      *> Each feature is rescaled with the training rows' mean and
      *> sample standard deviation, then the weights start at zero and
      *> take 1000 steps of batch gradient descent on the average
      *> log-loss. Values are fixed-point decimals carried to 18
      *> decimal places.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOGISTIC-REGRESSION.

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

      *> One CSV line split into fields, and where the columns are.
       01  WS-FIELDS.
           05  WS-FIELD             PIC X(40) OCCURS 20 TIMES.
       01  WS-FIELD-COUNT           PIC 99.
       01  WS-POINTER               PIC 999.
       01  WS-LINE-LENGTH           PIC 999.
       01  WS-HOURS-COLUMN          PIC 99 VALUE 0.
       01  WS-SLEEP-COLUMN          PIC 99 VALUE 0.
       01  WS-PASSED-COLUMN         PIC 99 VALUE 0.
       01  WS-SPLIT-COLUMN          PIC 99 VALUE 0.

      *> Every row: whether it is a training row, its two features (raw,
      *> then scaled in place), and its 0/1 label.
       01  WS-N                     PIC 9(4) VALUE 0.
       01  WS-TRAIN-COUNT           PIC 9(4) VALUE 0.
       01  WS-TEST-COUNT            PIC 9(4) VALUE 0.
       01  WS-ROWS.
           05  WS-ROW               OCCURS 5000 TIMES.
               10  WS-IS-TRAIN      PIC X.
               10  WS-X1            PIC S9(6)V9(18).
               10  WS-X2            PIC S9(6)V9(18).
               10  WS-Y             PIC 9.

      *> Training means and sample standard deviations.
       01  WS-MEAN-1                PIC S9(6)V9(18).
       01  WS-MEAN-2                PIC S9(6)V9(18).
       01  WS-SS-1                  PIC S9(9)V9(18).
       01  WS-SS-2                  PIC S9(9)V9(18).
       01  WS-SD-1                  PIC S9(6)V9(18).
       01  WS-SD-2                  PIC S9(6)V9(18).

      *> The weights (W0 is the intercept), the gradient sums, and one
      *> row's probability and error.
       01  WS-W0                    PIC S9(6)V9(18) VALUE 0.
       01  WS-W1                    PIC S9(6)V9(18) VALUE 0.
       01  WS-W2                    PIC S9(6)V9(18) VALUE 0.
       01  WS-G0                    PIC S9(9)V9(18).
       01  WS-G1                    PIC S9(9)V9(18).
       01  WS-G2                    PIC S9(9)V9(18).
       01  WS-P                     PIC S9(3)V9(18).
       01  WS-E                     PIC S9(3)V9(18).
       01  WS-LOSS                  PIC S9(9)V9(18).
       01  WS-LEARNING-RATE         PIC 9V9 VALUE 0.5.
       01  WS-STEPS                 PIC 9(4) VALUE 1000.

       01  I                        PIC 9(4).
       01  S                        PIC 9(4).
       01  WS-PREDICTED             PIC 9.
       01  WS-CORRECT               PIC 9(4) VALUE 0.

      *> Output: a name, then the value edited to six decimal places.
       01  WS-NAME                  PIC X(20).
       01  WS-RESULT                PIC S9(9)V9(18).
       01  WS-RESULT-OUT            PIC -(9)9.9(6).
       01  WS-COUNT-OUT             PIC Z(8)9.

       PROCEDURE DIVISION.
       MAIN.
           ACCEPT WS-FILE-NAME FROM ARGUMENT-VALUE
           OPEN INPUT DATA-FILE

           READ DATA-FILE
               AT END SET END-OF-FILE TO TRUE
           END-READ
           PERFORM SPLIT-LINE
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-FIELD-COUNT
               EVALUATE WS-FIELD(I)
                   WHEN "hours"  MOVE I TO WS-HOURS-COLUMN
                   WHEN "sleep"  MOVE I TO WS-SLEEP-COLUMN
                   WHEN "passed" MOVE I TO WS-PASSED-COLUMN
                   WHEN "split"  MOVE I TO WS-SPLIT-COLUMN
               END-EVALUATE
           END-PERFORM
           IF WS-HOURS-COLUMN = 0 OR WS-SLEEP-COLUMN = 0
                   OR WS-PASSED-COLUMN = 0 OR WS-SPLIT-COLUMN = 0
               DISPLAY "missing column" UPON SYSERR
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM UNTIL END-OF-FILE
               READ DATA-FILE
                   AT END SET END-OF-FILE TO TRUE
                   NOT AT END PERFORM ADD-ROW
               END-READ
           END-PERFORM
           CLOSE DATA-FILE

           PERFORM SCALE-FEATURES

      *>   Gradient descent: each step computes the whole gradient with
      *>   the old weights, then moves all three weights together.
           PERFORM VARYING S FROM 1 BY 1 UNTIL S > WS-STEPS
               MOVE 0 TO WS-G0 WS-G1 WS-G2
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
                   IF WS-IS-TRAIN(I) = "Y"
                       PERFORM SIGMOID
                       COMPUTE WS-E = WS-P - WS-Y(I)
                       ADD WS-E TO WS-G0
                       COMPUTE WS-G1 = WS-G1 + WS-E * WS-X1(I)
                       COMPUTE WS-G2 = WS-G2 + WS-E * WS-X2(I)
                   END-IF
               END-PERFORM
               COMPUTE WS-W0 ROUNDED = WS-W0
                   - WS-LEARNING-RATE * WS-G0 / WS-TRAIN-COUNT
               COMPUTE WS-W1 ROUNDED = WS-W1
                   - WS-LEARNING-RATE * WS-G1 / WS-TRAIN-COUNT
               COMPUTE WS-W2 ROUNDED = WS-W2
                   - WS-LEARNING-RATE * WS-G2 / WS-TRAIN-COUNT
           END-PERFORM

      *>   Average training log-loss, and test accuracy, with the final
      *>   weights.
           MOVE 0 TO WS-LOSS
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               PERFORM SIGMOID
               IF WS-IS-TRAIN(I) = "Y"
                   IF WS-Y(I) = 1
                       COMPUTE WS-LOSS = WS-LOSS - FUNCTION LOG(WS-P)
                   ELSE
                       COMPUTE WS-LOSS =
                           WS-LOSS - FUNCTION LOG(1 - WS-P)
                   END-IF
               ELSE
                   IF WS-P >= 0.5
                       MOVE 1 TO WS-PREDICTED
                   ELSE
                       MOVE 0 TO WS-PREDICTED
                   END-IF
                   IF WS-PREDICTED = WS-Y(I)
                       ADD 1 TO WS-CORRECT
                   END-IF
               END-IF
           END-PERFORM

           MOVE WS-TRAIN-COUNT TO WS-COUNT-OUT
           DISPLAY "train_count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-TEST-COUNT TO WS-COUNT-OUT
           DISPLAY "test_count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE "intercept" TO WS-NAME
           MOVE WS-W0 TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "weight_hours" TO WS-NAME
           MOVE WS-W1 TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "weight_sleep" TO WS-NAME
           MOVE WS-W2 TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "log_loss" TO WS-NAME
           COMPUTE WS-RESULT ROUNDED = WS-LOSS / WS-TRAIN-COUNT
           PERFORM PRINT-RESULT
           MOVE WS-CORRECT TO WS-COUNT-OUT
           DISPLAY "correct " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE "accuracy" TO WS-NAME
           COMPUTE WS-RESULT ROUNDED = WS-CORRECT / WS-TEST-COUNT
           PERFORM PRINT-RESULT

           STOP RUN.

      *> Split DATA-LINE on commas into WS-FIELD(1), WS-FIELD(2), ...
       SPLIT-LINE.
           MOVE SPACES TO WS-FIELDS
           MOVE 0 TO WS-FIELD-COUNT
           MOVE 1 TO WS-POINTER
           MOVE FUNCTION LENGTH(FUNCTION TRIM(DATA-LINE TRAILING))
               TO WS-LINE-LENGTH
           PERFORM UNTIL WS-POINTER > WS-LINE-LENGTH
               ADD 1 TO WS-FIELD-COUNT
               UNSTRING DATA-LINE DELIMITED BY ","
                   INTO WS-FIELD(WS-FIELD-COUNT)
                   WITH POINTER WS-POINTER
               END-UNSTRING
           END-PERFORM.

      *> Store one data line, and count it as training or test.
       ADD-ROW.
           PERFORM SPLIT-LINE
           ADD 1 TO WS-N
           IF WS-FIELD(WS-SPLIT-COLUMN) = "train"
               MOVE "Y" TO WS-IS-TRAIN(WS-N)
               ADD 1 TO WS-TRAIN-COUNT
           ELSE
               MOVE "N" TO WS-IS-TRAIN(WS-N)
               ADD 1 TO WS-TEST-COUNT
           END-IF
           COMPUTE WS-X1(WS-N) =
               FUNCTION NUMVAL(WS-FIELD(WS-HOURS-COLUMN))
           COMPUTE WS-X2(WS-N) =
               FUNCTION NUMVAL(WS-FIELD(WS-SLEEP-COLUMN))
           COMPUTE WS-Y(WS-N) =
               FUNCTION NUMVAL(WS-FIELD(WS-PASSED-COLUMN)).

      *> Rescale both features of every row with the training rows'
      *> mean and sample standard deviation (dividing by n - 1).
       SCALE-FEATURES.
           MOVE 0 TO WS-MEAN-1 WS-MEAN-2 WS-SS-1 WS-SS-2
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               IF WS-IS-TRAIN(I) = "Y"
                   ADD WS-X1(I) TO WS-MEAN-1
                   ADD WS-X2(I) TO WS-MEAN-2
               END-IF
           END-PERFORM
           COMPUTE WS-MEAN-1 ROUNDED = WS-MEAN-1 / WS-TRAIN-COUNT
           COMPUTE WS-MEAN-2 ROUNDED = WS-MEAN-2 / WS-TRAIN-COUNT
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               IF WS-IS-TRAIN(I) = "Y"
                   COMPUTE WS-SS-1 =
                       WS-SS-1 + (WS-X1(I) - WS-MEAN-1) ** 2
                   COMPUTE WS-SS-2 =
                       WS-SS-2 + (WS-X2(I) - WS-MEAN-2) ** 2
               END-IF
           END-PERFORM
           COMPUTE WS-SD-1 ROUNDED =
               FUNCTION SQRT(WS-SS-1 / (WS-TRAIN-COUNT - 1))
           COMPUTE WS-SD-2 ROUNDED =
               FUNCTION SQRT(WS-SS-2 / (WS-TRAIN-COUNT - 1))
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               COMPUTE WS-X1(I) ROUNDED =
                   (WS-X1(I) - WS-MEAN-1) / WS-SD-1
               COMPUTE WS-X2(I) ROUNDED =
                   (WS-X2(I) - WS-MEAN-2) / WS-SD-2
           END-PERFORM.

      *> WS-P = sigmoid(w . x) for row I, with the current weights.
       SIGMOID.
           COMPUTE WS-P ROUNDED = 1 / (1 + FUNCTION EXP(
               -(WS-W0 + WS-W1 * WS-X1(I) + WS-W2 * WS-X2(I)))).

      *> Print "name value", rounded to six decimal places.
       PRINT-RESULT.
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY FUNCTION TRIM(WS-NAME) " "
               FUNCTION TRIM(WS-RESULT-OUT).
