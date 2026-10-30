      *> Categorical naive Bayes with add-one (Laplace) smoothing, in
      *> COBOL.
      *>
      *> Learns P(label) and P(feature value | label) by counting
      *> training rows, then labels each test row with the label that
      *> has the highest log-probability.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. NAIVE-BAYES.

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
       01  WS-FEATURE-COUNT         PIC 9 VALUE 3.
       01  WS-FEATURE-NAMES.
           05  FILLER               PIC X(40) VALUE "has_link".
           05  FILLER               PIC X(40) VALUE "mentions_money".
           05  FILLER               PIC X(40) VALUE "known_sender".
       01  FILLER REDEFINES WS-FEATURE-NAMES.
           05  WS-FEATURE-NAME      PIC X(40) OCCURS 3 TIMES.
       01  WS-FEATURE-COLUMNS.
           05  WS-FEATURE-COLUMN    PIC 99 OCCURS 3 TIMES VALUE 0.
       01  WS-LABEL-COLUMN          PIC 99 VALUE 0.
       01  WS-SPLIT-COLUMN          PIC 99 VALUE 0.

      *> The distinct labels seen in training, with their row counts.
       01  WS-LABEL-COUNT           PIC 99 VALUE 0.
       01  WS-LABELS.
           05  WS-LABEL             OCCURS 20 TIMES.
               10  WS-LABEL-NAME    PIC X(40).
               10  WS-LABEL-ROWS    PIC 9(4) VALUE 0.

      *> For each feature: its distinct training values (m_j of them),
      *> and how many training rows of each label have each value.
       01  WS-FEATURES.
           05  WS-FEATURE           OCCURS 3 TIMES.
               10  WS-VALUE-COUNT   PIC 99 VALUE 0.
               10  WS-VALUE         OCCURS 20 TIMES.
                   15  WS-VALUE-NAME    PIC X(40).
                   15  WS-VALUE-ROWS    PIC 9(4) OCCURS 20 TIMES
                                        VALUE 0.

      *> Test rows: the field values, kept as text.
       01  WS-TEST-COUNT            PIC 9(4) VALUE 0.
       01  WS-TESTS.
           05  WS-TEST              OCCURS 5000 TIMES.
               10  WS-TEST-VALUE    PIC X(40) OCCURS 3 TIMES.
               10  WS-TEST-LABEL    PIC X(40).

       01  I                        PIC 9(4).
       01  F                        PIC 9.
       01  V                        PIC 99.
       01  L                        PIC 99.
       01  WS-FOUND                 PIC 99.
       01  WS-TRAIN-COUNT           PIC 9(4) VALUE 0.
       01  WS-MATCHES               PIC 9(4).
       01  WS-SCORE                 PIC S9(6)V9(12).
       01  WS-BEST-SCORE            PIC S9(6)V9(12).
       01  WS-BEST                  PIC 99.
       01  WS-CORRECT               PIC 9(4) VALUE 0.
       01  WS-ACCURACY              PIC S9(3)V9(12).
       01  WS-ACCURACY-OUT          PIC -(3)9.9(6).
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
               PERFORM VARYING F FROM 1 BY 1
                       UNTIL F > WS-FEATURE-COUNT
                   IF WS-FIELD(I) = WS-FEATURE-NAME(F)
                       MOVE I TO WS-FEATURE-COLUMN(F)
                   END-IF
               END-PERFORM
               IF WS-FIELD(I) = "label"
                   MOVE I TO WS-LABEL-COLUMN
               END-IF
               IF WS-FIELD(I) = "split"
                   MOVE I TO WS-SPLIT-COLUMN
               END-IF
           END-PERFORM
           IF WS-FEATURE-COLUMN(1) = 0 OR WS-FEATURE-COLUMN(2) = 0
                   OR WS-FEATURE-COLUMN(3) = 0
                   OR WS-LABEL-COLUMN = 0 OR WS-SPLIT-COLUMN = 0
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

           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-TEST-COUNT
               PERFORM CLASSIFY
               IF WS-LABEL-NAME(WS-BEST) = WS-TEST-LABEL(I)
                   ADD 1 TO WS-CORRECT
               END-IF
           END-PERFORM

           MOVE WS-TRAIN-COUNT TO WS-COUNT-OUT
           DISPLAY "train_count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-TEST-COUNT TO WS-COUNT-OUT
           DISPLAY "test_count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-CORRECT TO WS-COUNT-OUT
           DISPLAY "correct " FUNCTION TRIM(WS-COUNT-OUT)
           COMPUTE WS-ACCURACY ROUNDED = WS-CORRECT / WS-TEST-COUNT
           COMPUTE WS-ACCURACY-OUT ROUNDED = WS-ACCURACY
           DISPLAY "accuracy " FUNCTION TRIM(WS-ACCURACY-OUT)

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

      *> Count a training row, or keep a test row for later.
       ADD-ROW.
           PERFORM SPLIT-LINE
           IF WS-FIELD(WS-SPLIT-COLUMN) = "train"
               PERFORM COUNT-TRAINING-ROW
           ELSE
               ADD 1 TO WS-TEST-COUNT
               PERFORM VARYING F FROM 1 BY 1
                       UNTIL F > WS-FEATURE-COUNT
                   MOVE WS-FIELD(WS-FEATURE-COLUMN(F))
                       TO WS-TEST-VALUE(WS-TEST-COUNT, F)
               END-PERFORM
               MOVE WS-FIELD(WS-LABEL-COLUMN)
                   TO WS-TEST-LABEL(WS-TEST-COUNT)
           END-IF.

      *> Add one training row to the label and value counts, adding
      *> any label or value not seen before.
       COUNT-TRAINING-ROW.
           ADD 1 TO WS-TRAIN-COUNT
           MOVE 0 TO L
           PERFORM VARYING WS-FOUND FROM 1 BY 1
                   UNTIL WS-FOUND > WS-LABEL-COUNT
               IF WS-LABEL-NAME(WS-FOUND) = WS-FIELD(WS-LABEL-COLUMN)
                   MOVE WS-FOUND TO L
               END-IF
           END-PERFORM
           IF L = 0
               ADD 1 TO WS-LABEL-COUNT
               MOVE WS-LABEL-COUNT TO L
               MOVE WS-FIELD(WS-LABEL-COLUMN) TO WS-LABEL-NAME(L)
           END-IF
           ADD 1 TO WS-LABEL-ROWS(L)

           PERFORM VARYING F FROM 1 BY 1 UNTIL F > WS-FEATURE-COUNT
               MOVE 0 TO V
               PERFORM VARYING WS-FOUND FROM 1 BY 1
                       UNTIL WS-FOUND > WS-VALUE-COUNT(F)
                   IF WS-VALUE-NAME(F, WS-FOUND)
                           = WS-FIELD(WS-FEATURE-COLUMN(F))
                       MOVE WS-FOUND TO V
                   END-IF
               END-PERFORM
               IF V = 0
                   ADD 1 TO WS-VALUE-COUNT(F)
                   MOVE WS-VALUE-COUNT(F) TO V
                   MOVE WS-FIELD(WS-FEATURE-COLUMN(F))
                       TO WS-VALUE-NAME(F, V)
               END-IF
               ADD 1 TO WS-VALUE-ROWS(F, V, L)
           END-PERFORM.

      *> Pick the label with the highest log score for test row I,
      *> into WS-BEST.
       CLASSIFY.
           MOVE 0 TO WS-BEST
           PERFORM VARYING L FROM 1 BY 1 UNTIL L > WS-LABEL-COUNT
               PERFORM LOG-SCORE
      *>       An exact tie goes to the alphabetically first label.
               IF WS-BEST = 0
                   OR WS-SCORE > WS-BEST-SCORE
                   OR (WS-SCORE = WS-BEST-SCORE
                       AND WS-LABEL-NAME(L) < WS-LABEL-NAME(WS-BEST))
                   MOVE L TO WS-BEST
                   MOVE WS-SCORE TO WS-BEST-SCORE
               END-IF
           END-PERFORM.

      *> log P(label L) + sum of log P(value | label L), into WS-SCORE.
      *> Logs turn the product of probabilities into a sum, avoiding
      *> underflow. Each log of a ratio is taken as a difference of
      *> logs of whole numbers, so no quotient is truncated first.
       LOG-SCORE.
           COMPUTE WS-SCORE ROUNDED =
               FUNCTION LOG(WS-LABEL-ROWS(L))
               - FUNCTION LOG(WS-TRAIN-COUNT)
           PERFORM VARYING F FROM 1 BY 1 UNTIL F > WS-FEATURE-COUNT
      *>       A value never seen in training counts as zero rows.
               MOVE 0 TO WS-MATCHES
               PERFORM VARYING V FROM 1 BY 1
                       UNTIL V > WS-VALUE-COUNT(F)
                   IF WS-VALUE-NAME(F, V) = WS-TEST-VALUE(I, F)
                       MOVE WS-VALUE-ROWS(F, V, L) TO WS-MATCHES
                   END-IF
               END-PERFORM
      *>       Add-one smoothing: an unseen value never gets
      *>       probability zero.
               COMPUTE WS-SCORE ROUNDED = WS-SCORE
                   + FUNCTION LOG(WS-MATCHES + 1)
                   - FUNCTION LOG(WS-LABEL-ROWS(L) + WS-VALUE-COUNT(F))
           END-PERFORM.
