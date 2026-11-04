      *> Exact two-sided permutation test for a difference in means,
      *> in COBOL.
      *>
      *> If compost made no difference, the "compost" and "control"
      *> labels are arbitrary, and any 8 of the 16 plants could have
      *> carried the compost label. We try every one of those splits
      *> and count how many give a difference at least as large as the
      *> one we observed. That fraction is the p-value.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HYPOTHESIS-TESTS.

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
       01  WS-GROUP                 PIC X(40).
       01  WS-GRAMS-TEXT            PIC X(40).

      *> Every plant's grams, in file order. Grams are whole numbers,
      *> so every total below is an exact integer.
       01  WS-PLANT-COUNT           PIC 99 VALUE 0.
       01  WS-PLANTS.
           05  WS-GRAMS             PIC 9(6) OCCURS 64 TIMES.
       01  WS-CONTROL-COUNT         PIC 99 VALUE 0.
       01  WS-COMPOST-COUNT         PIC 99 VALUE 0.
       01  WS-CONTROL-SUM           PIC 9(9) VALUE 0.
       01  WS-COMPOST-SUM           PIC 9(9) VALUE 0.
       01  WS-TOTAL                 PIC 9(9) VALUE 0.
       01  WS-OBSERVED              PIC S9(9).
       01  WS-THRESHOLD             PIC 9(9).

      *> The current split: the positions of the plants labeled
      *> compost, in increasing order, such as 1 2 3 ... 8.
       01  WS-PICKS.
           05  WS-PICK              PIC 99 OCCURS 64 TIMES.
       01  WS-CHOSEN                PIC 9(9).
       01  WS-DIFFERENCE            PIC S9(9).
       01  WS-SPLITS                PIC 9(9) VALUE 0.
       01  WS-AS-EXTREME            PIC 9(9) VALUE 0.
       01  WS-DONE                  PIC X VALUE "N".
           88  ALL-SPLITS-DONE      VALUE "Y".

       01  I                        PIC 99.
       01  J                        PIC 99.
       01  WS-RESULT                PIC S9(9)V9(12).
       01  WS-RESULT-OUT            PIC -(9)9.9(6).
       01  WS-COUNT-OUT             PIC Z(8)9.

       PROCEDURE DIVISION.
       MAIN.
           ACCEPT WS-FILE-NAME FROM ARGUMENT-VALUE
           OPEN INPUT DATA-FILE
      *>   The first line is the header, group,grams; skip it.
           READ DATA-FILE
               AT END SET END-OF-FILE TO TRUE
           END-READ
           PERFORM UNTIL END-OF-FILE
               READ DATA-FILE
                   AT END SET END-OF-FILE TO TRUE
                   NOT AT END PERFORM ADD-PLANT
               END-READ
           END-PERFORM
           CLOSE DATA-FILE
           IF WS-COMPOST-COUNT = 0
                   OR WS-COMPOST-COUNT NOT = WS-CONTROL-COUNT
               DISPLAY "need two groups of equal size" UPON SYSERR
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

      *>   Both groups have the same size, so comparing totals is the
      *>   same as comparing means.
           COMPUTE WS-TOTAL = WS-CONTROL-SUM + WS-COMPOST-SUM
           COMPUTE WS-OBSERVED = WS-COMPOST-SUM - WS-CONTROL-SUM
           COMPUTE WS-THRESHOLD = FUNCTION ABS(WS-OBSERVED)

      *>   Start from the first split, positions 1 to N, and step
      *>   through every split in increasing order.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-COMPOST-COUNT
               MOVE I TO WS-PICK(I)
           END-PERFORM
           PERFORM UNTIL ALL-SPLITS-DONE
               PERFORM SCORE-SPLIT
               PERFORM NEXT-SPLIT
           END-PERFORM

           MOVE WS-CONTROL-COUNT TO WS-COUNT-OUT
           DISPLAY "control_count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-COMPOST-COUNT TO WS-COUNT-OUT
           DISPLAY "compost_count " FUNCTION TRIM(WS-COUNT-OUT)
           COMPUTE WS-RESULT ROUNDED =
               WS-CONTROL-SUM / WS-CONTROL-COUNT
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY "control_mean " FUNCTION TRIM(WS-RESULT-OUT)
           COMPUTE WS-RESULT ROUNDED =
               WS-COMPOST-SUM / WS-COMPOST-COUNT
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY "compost_mean " FUNCTION TRIM(WS-RESULT-OUT)
           COMPUTE WS-RESULT ROUNDED = WS-OBSERVED / WS-COMPOST-COUNT
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY "observed_difference " FUNCTION TRIM(WS-RESULT-OUT)
           MOVE WS-SPLITS TO WS-COUNT-OUT
           DISPLAY "splits " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-AS-EXTREME TO WS-COUNT-OUT
           DISPLAY "as_extreme " FUNCTION TRIM(WS-COUNT-OUT)
           COMPUTE WS-RESULT ROUNDED = WS-AS-EXTREME / WS-SPLITS
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY "p_value " FUNCTION TRIM(WS-RESULT-OUT)

           STOP RUN.

      *> Store one group,grams line.
       ADD-PLANT.
           MOVE SPACES TO WS-GROUP WS-GRAMS-TEXT
           UNSTRING DATA-LINE DELIMITED BY ","
               INTO WS-GROUP WS-GRAMS-TEXT
           END-UNSTRING
           IF WS-GROUP = SPACES
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-PLANT-COUNT
           COMPUTE WS-GRAMS(WS-PLANT-COUNT) =
               FUNCTION NUMVAL(WS-GRAMS-TEXT)
           IF WS-GROUP = "compost"
               ADD 1 TO WS-COMPOST-COUNT
               ADD WS-GRAMS(WS-PLANT-COUNT) TO WS-COMPOST-SUM
           ELSE
               ADD 1 TO WS-CONTROL-COUNT
               ADD WS-GRAMS(WS-PLANT-COUNT) TO WS-CONTROL-SUM
           END-IF.

      *> Count the current split, and whether it is as extreme as the
      *> observed one, in either direction.
       SCORE-SPLIT.
           MOVE 0 TO WS-CHOSEN
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-COMPOST-COUNT
               ADD WS-GRAMS(WS-PICK(I)) TO WS-CHOSEN
           END-PERFORM
           COMPUTE WS-DIFFERENCE = WS-CHOSEN - (WS-TOTAL - WS-CHOSEN)
           ADD 1 TO WS-SPLITS
           IF FUNCTION ABS(WS-DIFFERENCE) >= WS-THRESHOLD
               ADD 1 TO WS-AS-EXTREME
           END-IF.

      *> Step to the next split in increasing order: find the last pick
      *> that can still move right, move it one place, and put the
      *> picks after it just behind it. Pick I can go no further than
      *> position PLANT-COUNT - N + I, so when even pick 1 is there,
      *> that was the last split.
       NEXT-SPLIT.
           MOVE WS-COMPOST-COUNT TO I
           PERFORM UNTIL I = 0
                   OR WS-PICK(I) <
                      WS-PLANT-COUNT - WS-COMPOST-COUNT + I
               SUBTRACT 1 FROM I
           END-PERFORM
           IF I = 0
               SET ALL-SPLITS-DONE TO TRUE
           ELSE
               ADD 1 TO WS-PICK(I)
               PERFORM VARYING J FROM I BY 1
                       UNTIL J >= WS-COMPOST-COUNT
                   COMPUTE WS-PICK(J + 1) = WS-PICK(J) + 1
               END-PERFORM
           END-IF.
