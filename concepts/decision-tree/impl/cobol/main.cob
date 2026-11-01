      *> A decision tree classifier (CART with Gini impurity), in COBOL.
      *>
      *> Grows a tree on the training days by always making the split
      *> that leaves the two sides purest, then predicts rain for the
      *> test days. COBOL paragraphs can't recurse, so nodes wait on an
      *> explicit stack; popping left before right visits them in
      *> preorder, and each node is printed as soon as it is decided.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DECISION-TREE.

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
       01  WS-MAX-DEPTH             PIC 9 VALUE 3.
       01  WS-MIN-SIZE              PIC 9 VALUE 5.
       01  WS-EOF                   PIC X VALUE "N".
           88  END-OF-FILE          VALUE "Y".

      *> One CSV line split into fields, and where the columns are.
       01  WS-FIELDS.
           05  WS-FIELD             PIC X(40) OCCURS 20 TIMES.
       01  WS-FIELD-COUNT           PIC 99.
       01  WS-POINTER               PIC 999.
       01  WS-LINE-LENGTH           PIC 999.
       01  WS-FEATURE-NAMES.
           05  FILLER               PIC X(40) VALUE "humidity".
           05  FILLER               PIC X(40) VALUE "pressure".
           05  FILLER               PIC X(40) VALUE "wind".
       01  FILLER REDEFINES WS-FEATURE-NAMES.
           05  WS-FEATURE-NAME      PIC X(40) OCCURS 3 TIMES.
       01  WS-FEATURE-COLUMNS.
           05  WS-FEATURE-COLUMN    PIC 99 OCCURS 3 TIMES VALUE 0.
       01  WS-LABEL-COLUMN          PIC 99 VALUE 0.
       01  WS-SPLIT-COLUMN          PIC 99 VALUE 0.

      *> Every day, train and test. WS-DAY-NODE is the tree node a
      *> training day currently sits in while the tree grows.
       01  WS-DAY-COUNT             PIC 9(4) VALUE 0.
       01  WS-DAYS.
           05  WS-DAY               OCCURS 5000 TIMES.
               10  WS-X             PIC S9(6)V9(6) OCCURS 3 TIMES.
               10  WS-RAIN          PIC X(3).
               10  WS-IS-TRAIN      PIC X.
               10  WS-DAY-NODE      PIC 99.

      *> The tree: depth 3 allows at most 15 nodes. A split node has a
      *> feature, a threshold, and two children; a leaf has a label.
       01  WS-NODE-COUNT            PIC 99 VALUE 0.
       01  WS-NODES.
           05  WS-NODE              OCCURS 15 TIMES.
               10  WS-NODE-DEPTH    PIC 9.
               10  WS-NODE-FEATURE  PIC 9 VALUE 0.
               10  WS-NODE-THRESHOLD    PIC S9(6)V9(6).
               10  WS-NODE-LEFT     PIC 99.
               10  WS-NODE-RIGHT    PIC 99.
               10  WS-NODE-PREDICT  PIC X(3).
       01  WS-STACK-SIZE            PIC 99 VALUE 0.
       01  WS-STACK.
           05  WS-STACK-NODE        PIC 99 OCCURS 15 TIMES.

       01  I                        PIC 9(4).
       01  F                        PIC 9.
       01  K                        PIC 99.
       01  WS-PREORDER              PIC 99 VALUE 0.
       01  WS-LEAVES                PIC 99 VALUE 0.
       01  WS-N                     PIC 9(4).
       01  WS-YES                   PIC 9(4).
       01  WS-N-LEFT                PIC 9(4).
       01  WS-YES-LEFT              PIC 9(4).
       01  WS-GINI                  PIC S9V9(18).
       01  WS-GINI-LEFT             PIC S9V9(18).
       01  WS-GINI-RIGHT            PIC S9V9(18).
       01  WS-P                     PIC S9V9(18).
       01  WS-SCORE                 PIC S9V9(18).
       01  WS-BEST-SCORE            PIC S9V9(18).
       01  WS-BEST-FEATURE          PIC 9.
       01  WS-BEST-THRESHOLD        PIC S9(6)V9(6).
       01  WS-LOW                   PIC S9(6)V9(6).
       01  WS-NEXT                  PIC S9(6)V9(6).
       01  WS-HAS-NEXT              PIC X.
       01  WS-THRESHOLD             PIC S9(6)V9(6).
       01  WS-PREDICTED             PIC X(3).
       01  WS-TRAIN-COUNT           PIC 9(4) VALUE 0.
       01  WS-TEST-COUNT            PIC 9(4) VALUE 0.
       01  WS-TRAIN-CORRECT         PIC 9(4) VALUE 0.
       01  WS-CORRECT               PIC 9(4) VALUE 0.
       01  WS-ACCURACY              PIC S9(3)V9(12).
       01  WS-DECIMAL-OUT           PIC -(7)9.9(6).
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
               PERFORM VARYING F FROM 1 BY 1 UNTIL F > 3
                   IF WS-FIELD(I) = WS-FEATURE-NAME(F)
                       MOVE I TO WS-FEATURE-COLUMN(F)
                   END-IF
               END-PERFORM
               IF WS-FIELD(I) = "rain"
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
                   NOT AT END PERFORM ADD-DAY
               END-READ
           END-PERFORM
           CLOSE DATA-FILE

           MOVE WS-TRAIN-COUNT TO WS-COUNT-OUT
           DISPLAY "train_count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-TEST-COUNT TO WS-COUNT-OUT
           DISPLAY "test_count " FUNCTION TRIM(WS-COUNT-OUT)

      *>   Every training day starts in the root, node 1, at depth 0.
           MOVE 1 TO WS-NODE-COUNT
           MOVE 0 TO WS-NODE-DEPTH(1)
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-DAY-COUNT
               MOVE 1 TO WS-DAY-NODE(I)
           END-PERFORM
           MOVE 1 TO WS-STACK-SIZE
           MOVE 1 TO WS-STACK-NODE(1)
           PERFORM UNTIL WS-STACK-SIZE = 0
               MOVE WS-STACK-NODE(WS-STACK-SIZE) TO K
               SUBTRACT 1 FROM WS-STACK-SIZE
               PERFORM GROW-NODE
           END-PERFORM
           MOVE WS-LEAVES TO WS-COUNT-OUT
           DISPLAY "leaves " FUNCTION TRIM(WS-COUNT-OUT)

           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-DAY-COUNT
               PERFORM PREDICT
               IF WS-PREDICTED = WS-RAIN(I)
                   IF WS-IS-TRAIN(I) = "Y"
                       ADD 1 TO WS-TRAIN-CORRECT
                   ELSE
                       ADD 1 TO WS-CORRECT
                   END-IF
               END-IF
           END-PERFORM
           COMPUTE WS-ACCURACY ROUNDED =
               WS-TRAIN-CORRECT / WS-TRAIN-COUNT
           COMPUTE WS-DECIMAL-OUT ROUNDED = WS-ACCURACY
           DISPLAY "train_accuracy " FUNCTION TRIM(WS-DECIMAL-OUT)
           MOVE WS-CORRECT TO WS-COUNT-OUT
           DISPLAY "correct " FUNCTION TRIM(WS-COUNT-OUT)
           COMPUTE WS-ACCURACY ROUNDED = WS-CORRECT / WS-TEST-COUNT
           COMPUTE WS-DECIMAL-OUT ROUNDED = WS-ACCURACY
           DISPLAY "accuracy " FUNCTION TRIM(WS-DECIMAL-OUT)

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

      *> Store one data line as a day, marked train or test.
       ADD-DAY.
           PERFORM SPLIT-LINE
           ADD 1 TO WS-DAY-COUNT
           PERFORM VARYING F FROM 1 BY 1 UNTIL F > 3
               COMPUTE WS-X(WS-DAY-COUNT, F) =
                   FUNCTION NUMVAL(WS-FIELD(WS-FEATURE-COLUMN(F)))
           END-PERFORM
           MOVE WS-FIELD(WS-LABEL-COLUMN) TO WS-RAIN(WS-DAY-COUNT)
           IF WS-FIELD(WS-SPLIT-COLUMN) = "train"
               MOVE "Y" TO WS-IS-TRAIN(WS-DAY-COUNT)
               ADD 1 TO WS-TRAIN-COUNT
           ELSE
               MOVE "N" TO WS-IS-TRAIN(WS-DAY-COUNT)
               ADD 1 TO WS-TEST-COUNT
           END-IF.

      *> Decide node K: make it a leaf, or split it and push its two
      *> children, right first so the left one is popped next.
       GROW-NODE.
           ADD 1 TO WS-PREORDER
           MOVE 0 TO WS-N WS-YES
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-DAY-COUNT
               IF WS-IS-TRAIN(I) = "Y" AND WS-DAY-NODE(I) = K
                   ADD 1 TO WS-N
                   IF WS-RAIN(I) = "yes"
                       ADD 1 TO WS-YES
                   END-IF
               END-IF
           END-PERFORM
           COMPUTE WS-P ROUNDED = WS-YES / WS-N
           COMPUTE WS-GINI ROUNDED = 1 - WS-P ** 2 - (1 - WS-P) ** 2

           MOVE 9 TO WS-BEST-SCORE
           IF WS-GINI > 0 AND WS-N >= WS-MIN-SIZE
                   AND WS-NODE-DEPTH(K) < WS-MAX-DEPTH
               PERFORM BEST-SPLIT
           END-IF
      *>   No split was tried, or none makes the sides purer.
           IF WS-BEST-SCORE >= WS-GINI
               ADD 1 TO WS-LEAVES
      *>       An even split predicts "no".
               IF WS-YES * 2 > WS-N
                   MOVE "yes" TO WS-NODE-PREDICT(K)
               ELSE
                   MOVE "no" TO WS-NODE-PREDICT(K)
               END-IF
               MOVE WS-PREORDER TO WS-COUNT-OUT
               DISPLAY "node_" FUNCTION TRIM(WS-COUNT-OUT) "_predict "
                   FUNCTION TRIM(WS-NODE-PREDICT(K))
               EXIT PARAGRAPH
           END-IF

           MOVE WS-BEST-FEATURE TO WS-NODE-FEATURE(K)
           MOVE WS-BEST-THRESHOLD TO WS-NODE-THRESHOLD(K)
           MOVE WS-PREORDER TO WS-COUNT-OUT
           DISPLAY "node_" FUNCTION TRIM(WS-COUNT-OUT) "_feature "
               FUNCTION TRIM(WS-FEATURE-NAME(WS-BEST-FEATURE))
           MOVE WS-BEST-THRESHOLD TO WS-DECIMAL-OUT
           DISPLAY "node_" FUNCTION TRIM(WS-COUNT-OUT) "_threshold "
               FUNCTION TRIM(WS-DECIMAL-OUT)

           COMPUTE WS-NODE-LEFT(K) = WS-NODE-COUNT + 1
           COMPUTE WS-NODE-RIGHT(K) = WS-NODE-COUNT + 2
           ADD 2 TO WS-NODE-COUNT
           COMPUTE WS-NODE-DEPTH(WS-NODE-LEFT(K)) = WS-NODE-DEPTH(K) + 1
           COMPUTE WS-NODE-DEPTH(WS-NODE-RIGHT(K)) =
               WS-NODE-DEPTH(K) + 1
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-DAY-COUNT
               IF WS-IS-TRAIN(I) = "Y" AND WS-DAY-NODE(I) = K
                   IF WS-X(I, WS-BEST-FEATURE) <= WS-BEST-THRESHOLD
                       MOVE WS-NODE-LEFT(K) TO WS-DAY-NODE(I)
                   ELSE
                       MOVE WS-NODE-RIGHT(K) TO WS-DAY-NODE(I)
                   END-IF
               END-IF
           END-PERFORM
           ADD 1 TO WS-STACK-SIZE
           MOVE WS-NODE-RIGHT(K) TO WS-STACK-NODE(WS-STACK-SIZE)
           ADD 1 TO WS-STACK-SIZE
           MOVE WS-NODE-LEFT(K) TO WS-STACK-NODE(WS-STACK-SIZE).

      *> The lowest weighted Gini impurity over every feature and
      *> threshold for node K. Features go in column order, thresholds
      *> from smallest to largest, and only a strictly lower score
      *> replaces the best so far.
       BEST-SPLIT.
           PERFORM VARYING F FROM 1 BY 1 UNTIL F > 3
      *>       Start at the node's smallest value, then step through
      *>       the distinct values in order without sorting them.
               MOVE 999999 TO WS-LOW
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-DAY-COUNT
                   IF WS-IS-TRAIN(I) = "Y" AND WS-DAY-NODE(I) = K
                           AND WS-X(I, F) < WS-LOW
                       MOVE WS-X(I, F) TO WS-LOW
                   END-IF
               END-PERFORM
               MOVE "Y" TO WS-HAS-NEXT
               PERFORM UNTIL WS-HAS-NEXT = "N"
                   PERFORM FIND-NEXT-VALUE
                   IF WS-HAS-NEXT = "Y"
                       COMPUTE WS-THRESHOLD = (WS-LOW + WS-NEXT) / 2
                       PERFORM SCORE-SPLIT
                       IF WS-SCORE < WS-BEST-SCORE
                           MOVE WS-SCORE TO WS-BEST-SCORE
                           MOVE F TO WS-BEST-FEATURE
                           MOVE WS-THRESHOLD TO WS-BEST-THRESHOLD
                       END-IF
                       MOVE WS-NEXT TO WS-LOW
                   END-IF
               END-PERFORM
           END-PERFORM.

      *> The smallest value of feature F in node K above WS-LOW, into
      *> WS-NEXT, or WS-HAS-NEXT = "N" if there is none.
       FIND-NEXT-VALUE.
           MOVE "N" TO WS-HAS-NEXT
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-DAY-COUNT
               IF WS-IS-TRAIN(I) = "Y" AND WS-DAY-NODE(I) = K
                       AND WS-X(I, F) > WS-LOW
                   IF WS-HAS-NEXT = "N" OR WS-X(I, F) < WS-NEXT
                       MOVE WS-X(I, F) TO WS-NEXT
                       MOVE "Y" TO WS-HAS-NEXT
                   END-IF
               END-IF
           END-PERFORM.

      *> (nL * giniL + nR * giniR) / n for feature F at WS-THRESHOLD,
      *> into WS-SCORE. Left is value <= threshold.
       SCORE-SPLIT.
           MOVE 0 TO WS-N-LEFT WS-YES-LEFT
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-DAY-COUNT
               IF WS-IS-TRAIN(I) = "Y" AND WS-DAY-NODE(I) = K
                       AND WS-X(I, F) <= WS-THRESHOLD
                   ADD 1 TO WS-N-LEFT
                   IF WS-RAIN(I) = "yes"
                       ADD 1 TO WS-YES-LEFT
                   END-IF
               END-IF
           END-PERFORM
      *>   Both sides hold at least one day, since the threshold lies
      *>   between two values present in the node.
           COMPUTE WS-P ROUNDED = WS-YES-LEFT / WS-N-LEFT
           COMPUTE WS-GINI-LEFT ROUNDED =
               1 - WS-P ** 2 - (1 - WS-P) ** 2
           COMPUTE WS-P ROUNDED =
               (WS-YES - WS-YES-LEFT) / (WS-N - WS-N-LEFT)
           COMPUTE WS-GINI-RIGHT ROUNDED =
               1 - WS-P ** 2 - (1 - WS-P) ** 2
           COMPUTE WS-SCORE ROUNDED =
               (WS-N-LEFT * WS-GINI-LEFT
                + (WS-N - WS-N-LEFT) * WS-GINI-RIGHT) / WS-N.

      *> Walk day I down from the root to a leaf, into WS-PREDICTED.
       PREDICT.
           MOVE 1 TO K
           PERFORM UNTIL WS-NODE-FEATURE(K) = 0
               IF WS-X(I, WS-NODE-FEATURE(K)) <= WS-NODE-THRESHOLD(K)
                   MOVE WS-NODE-LEFT(K) TO K
               ELSE
                   MOVE WS-NODE-RIGHT(K) TO K
               END-IF
           END-PERFORM
           MOVE WS-NODE-PREDICT(K) TO WS-PREDICTED.
