      *> k-nearest neighbors classification, in COBOL.
      *>
      *> Each test seed is labelled with the majority variety among its
      *> K = 5 nearest training seeds. Squared Euclidean distance ranks
      *> the neighbors in the same order as distance, without a SQRT.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. K-NEAREST-NEIGHBORS.

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
       01  WS-K                     PIC 9 VALUE 5.
       01  WS-EOF                   PIC X VALUE "N".
           88  END-OF-FILE          VALUE "Y".

      *> One CSV line split into fields, and where the columns are.
       01  WS-FIELDS.
           05  WS-FIELD             PIC X(40) OCCURS 20 TIMES.
       01  WS-FIELD-COUNT           PIC 99.
       01  WS-POINTER               PIC 999.
       01  WS-LINE-LENGTH           PIC 999.
       01  WS-COLUMNS.
           05  WS-LENGTH-COLUMN     PIC 99 VALUE 0.
           05  WS-WIDTH-COLUMN      PIC 99 VALUE 0.
           05  WS-LABEL-COLUMN      PIC 99 VALUE 0.
           05  WS-SPLIT-COLUMN      PIC 99 VALUE 0.

      *> Training and test seeds: two features and a label each.
       01  WS-TRAIN-COUNT           PIC 9(4) VALUE 0.
       01  WS-TRAIN.
           05  WS-TRAIN-SEED        OCCURS 5000 TIMES.
               10  WS-TRAIN-X1      PIC S9(9)V9(6).
               10  WS-TRAIN-X2      PIC S9(9)V9(6).
               10  WS-TRAIN-LABEL   PIC X(40).
      *>       Squared distance to the current test seed, and whether
      *>       this seed has already been picked as a neighbor.
               10  WS-DIST          PIC S9(12)V9(12).
               10  WS-USED          PIC X.
       01  WS-TEST-COUNT            PIC 9(4) VALUE 0.
       01  WS-TEST.
           05  WS-TEST-SEED         OCCURS 5000 TIMES.
               10  WS-TEST-X1       PIC S9(9)V9(6).
               10  WS-TEST-X2       PIC S9(9)V9(6).
               10  WS-TEST-LABEL    PIC X(40).

      *> The votes of the K nearest, one entry per distinct label.
       01  WS-VOTE-COUNT            PIC 9.
       01  WS-VOTES.
           05  WS-VOTE              OCCURS 5 TIMES.
               10  WS-VOTE-LABEL    PIC X(40).
               10  WS-VOTE-TALLY    PIC 9.

       01  I                        PIC 9(4).
       01  T                        PIC 9(4).
       01  N                        PIC 9.
       01  V                        PIC 9.
       01  WS-BEST                  PIC 9(4).
       01  WS-PREDICTED             PIC X(40).
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
               EVALUATE WS-FIELD(I)
                   WHEN "length_mm" MOVE I TO WS-LENGTH-COLUMN
                   WHEN "width_mm"  MOVE I TO WS-WIDTH-COLUMN
                   WHEN "variety"   MOVE I TO WS-LABEL-COLUMN
                   WHEN "split"     MOVE I TO WS-SPLIT-COLUMN
               END-EVALUATE
           END-PERFORM
           IF WS-LENGTH-COLUMN = 0 OR WS-WIDTH-COLUMN = 0
                   OR WS-LABEL-COLUMN = 0 OR WS-SPLIT-COLUMN = 0
               DISPLAY "missing column" UPON SYSERR
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM UNTIL END-OF-FILE
               READ DATA-FILE
                   AT END SET END-OF-FILE TO TRUE
                   NOT AT END PERFORM ADD-SEED
               END-READ
           END-PERFORM
           CLOSE DATA-FILE

           PERFORM VARYING T FROM 1 BY 1 UNTIL T > WS-TEST-COUNT
               PERFORM CLASSIFY
               IF WS-PREDICTED = WS-TEST-LABEL(T)
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

      *> Store one data line as a training or a test seed.
       ADD-SEED.
           PERFORM SPLIT-LINE
           IF WS-FIELD(WS-SPLIT-COLUMN) = "train"
               ADD 1 TO WS-TRAIN-COUNT
               COMPUTE WS-TRAIN-X1(WS-TRAIN-COUNT) =
                   FUNCTION NUMVAL(WS-FIELD(WS-LENGTH-COLUMN))
               COMPUTE WS-TRAIN-X2(WS-TRAIN-COUNT) =
                   FUNCTION NUMVAL(WS-FIELD(WS-WIDTH-COLUMN))
               MOVE WS-FIELD(WS-LABEL-COLUMN)
                   TO WS-TRAIN-LABEL(WS-TRAIN-COUNT)
           ELSE
               ADD 1 TO WS-TEST-COUNT
               COMPUTE WS-TEST-X1(WS-TEST-COUNT) =
                   FUNCTION NUMVAL(WS-FIELD(WS-LENGTH-COLUMN))
               COMPUTE WS-TEST-X2(WS-TEST-COUNT) =
                   FUNCTION NUMVAL(WS-FIELD(WS-WIDTH-COLUMN))
               MOVE WS-FIELD(WS-LABEL-COLUMN)
                   TO WS-TEST-LABEL(WS-TEST-COUNT)
           END-IF.

      *> Label test seed T by majority vote of its K nearest seeds.
       CLASSIFY.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-TRAIN-COUNT
               COMPUTE WS-DIST(I) =
                   (WS-TEST-X1(T) - WS-TRAIN-X1(I)) ** 2
                   + (WS-TEST-X2(T) - WS-TRAIN-X2(I)) ** 2
               MOVE "N" TO WS-USED(I)
           END-PERFORM

      *>   Pick the nearest unused seed K times. A strict "<" keeps the
      *>   earlier training seed when two distances are equal.
           MOVE 0 TO WS-VOTE-COUNT
           PERFORM VARYING N FROM 1 BY 1 UNTIL N > WS-K
               MOVE 0 TO WS-BEST
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-TRAIN-COUNT
                   IF WS-USED(I) = "N"
                       IF WS-BEST = 0
                           MOVE I TO WS-BEST
                       ELSE
                           IF WS-DIST(I) < WS-DIST(WS-BEST)
                               MOVE I TO WS-BEST
                           END-IF
                       END-IF
                   END-IF
               END-PERFORM
               MOVE "Y" TO WS-USED(WS-BEST)
               PERFORM ADD-VOTE
           END-PERFORM

      *>   Labels are in the order first seen among the nearest, so a
      *>   strict ">" gives a tied vote to the label met first.
           MOVE 1 TO V
           PERFORM VARYING N FROM 2 BY 1 UNTIL N > WS-VOTE-COUNT
               IF WS-VOTE-TALLY(N) > WS-VOTE-TALLY(V)
                   MOVE N TO V
               END-IF
           END-PERFORM
           MOVE WS-VOTE-LABEL(V) TO WS-PREDICTED.

      *> Count one vote for the label of training seed WS-BEST.
       ADD-VOTE.
           MOVE 0 TO V
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-VOTE-COUNT
               IF WS-VOTE-LABEL(I) = WS-TRAIN-LABEL(WS-BEST)
                   MOVE I TO V
               END-IF
           END-PERFORM
           IF V = 0
               ADD 1 TO WS-VOTE-COUNT
               MOVE WS-VOTE-COUNT TO V
               MOVE WS-TRAIN-LABEL(WS-BEST) TO WS-VOTE-LABEL(V)
               MOVE 0 TO WS-VOTE-TALLY(V)
           END-IF
           ADD 1 TO WS-VOTE-TALLY(V).
