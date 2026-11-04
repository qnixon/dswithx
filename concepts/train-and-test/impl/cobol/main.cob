      *> Train and test error for polynomials of degree 1 to 8, in
      *> COBOL.
      *>
      *> Each polynomial is fitted by least squares to the training
      *> drives only: we build the normal equations and solve them by
      *> Gaussian elimination. Then we measure its root-mean-square
      *> error on the training drives and on the test drives it never
      *> saw.
      *> Values are fixed-point decimals carried to 18 decimal places.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TRAIN-AND-TEST.

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

      *> One CSV line split into fields.
       01  WS-FIELDS.
           05  WS-FIELD             PIC X(40) OCCURS 20 TIMES.
       01  WS-FIELD-COUNT           PIC 99.
       01  WS-POINTER               PIC 999.
       01  WS-LINE-LENGTH           PIC 999.

      *> Which CSV column holds each value, found from the header.
       01  WS-SPEED-COL             PIC 99 VALUE 0.
       01  WS-LITRES-COL            PIC 99 VALUE 0.
       01  WS-SPLIT-COL             PIC 99 VALUE 0.

      *> Every drive: its speed, scaled speed Z, litres, and split.
       01  WS-N                     PIC 9(4) VALUE 0.
       01  WS-DRIVES.
           05  WS-DRIVE             OCCURS 1000 TIMES.
               10  WS-SPEED         PIC S9(6)V9(18).
               10  WS-Z             PIC S9(3)V9(18).
               10  WS-Y             PIC S9(6)V9(18).
               10  WS-IS-TRAIN      PIC X.
       01  WS-TRAIN-COUNT           PIC 9(4) VALUE 0.
       01  WS-TEST-COUNT            PIC 9(4) VALUE 0.

      *> The training range, which maps every speed onto -1 to 1.
       01  WS-LOW                   PIC S9(6)V9(18).
       01  WS-HIGH                  PIC S9(6)V9(18).
       01  WS-MID                   PIC S9(6)V9(18).
       01  WS-HALF                  PIC S9(6)V9(18).

       01  MAX-DEGREE               PIC 9 VALUE 8.
       01  D                        PIC 9.
       01  N                        PIC 99.

      *> The augmented normal equations: up to 9 rows of 10 entries, the
      *> last entry of each row being b. WS-A-ROW(I) is a group item,
      *> so one MOVE copies a whole row.
       01  WS-A-TABLE.
           05  WS-A-ROW             OCCURS 9 TIMES.
               10  WS-A             PIC S9(9)V9(18) OCCURS 10 TIMES.
       01  WS-SPARE-ROW.
           05  FILLER               PIC S9(9)V9(18) OCCURS 10 TIMES.

      *> The powers z^0 to z^16 of one drive's scaled speed: WS-POW(E)
      *> holds z^(E - 1), because tables count from 1.
       01  WS-POW-TABLE.
           05  WS-POW               PIC S9(3)V9(18) OCCURS 17 TIMES.

      *> The fitted coefficients, and each degree's two errors.
       01  WS-X-TABLE.
           05  WS-X                 PIC S9(9)V9(18) OCCURS 9 TIMES.
       01  WS-ERRORS.
           05  WS-TRAIN-ERROR       PIC S9(3)V9(18) OCCURS 8 TIMES.
           05  WS-TEST-ERROR        PIC S9(3)V9(18) OCCURS 8 TIMES.
       01  WS-WHICH                 PIC X.
       01  WS-RMSE                  PIC S9(3)V9(18).

       01  WS-SUM                   PIC S9(9)V9(18).
       01  WS-FACTOR                PIC S9(9)V9(18).
       01  WS-PREDICTED             PIC S9(9)V9(18).
       01  WS-POWER                 PIC S9(3)V9(18).
       01  WS-COUNT                 PIC 9(4).
       01  PIVOT                    PIC 99.
       01  I                        PIC 99.
       01  J                        PIC 99.
       01  K                        PIC 99.
       01  R                        PIC 99.
       01  C                        PIC 99.
       01  S                        PIC 9(4).

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
                   WHEN "speed"  MOVE I TO WS-SPEED-COL
                   WHEN "litres" MOVE I TO WS-LITRES-COL
                   WHEN "split"  MOVE I TO WS-SPLIT-COL
               END-EVALUATE
           END-PERFORM
           IF WS-SPEED-COL = 0 OR WS-LITRES-COL = 0
                   OR WS-SPLIT-COL = 0
               DISPLAY "missing column" UPON SYSERR
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM UNTIL END-OF-FILE
               READ DATA-FILE
                   AT END SET END-OF-FILE TO TRUE
                   NOT AT END PERFORM ADD-DRIVE
               END-READ
           END-PERFORM
           CLOSE DATA-FILE

           PERFORM SCALE-SPEEDS

           PERFORM VARYING D FROM 1 BY 1 UNTIL D > MAX-DEGREE
               COMPUTE N = D + 1
               PERFORM BUILD-SYSTEM
               PERFORM SOLVE
               MOVE "Y" TO WS-WHICH
               PERFORM MEASURE-RMSE
               MOVE WS-RMSE TO WS-TRAIN-ERROR(D)
               MOVE "N" TO WS-WHICH
               PERFORM MEASURE-RMSE
               MOVE WS-RMSE TO WS-TEST-ERROR(D)
           END-PERFORM

           MOVE WS-TRAIN-COUNT TO WS-COUNT-OUT
           DISPLAY "train_count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE WS-TEST-COUNT TO WS-COUNT-OUT
           DISPLAY "test_count " FUNCTION TRIM(WS-COUNT-OUT)
           PERFORM VARYING D FROM 1 BY 1 UNTIL D > MAX-DEGREE
               MOVE SPACES TO WS-NAME
               STRING "train_rmse_d" D DELIMITED BY SIZE INTO WS-NAME
               MOVE WS-TRAIN-ERROR(D) TO WS-RESULT
               PERFORM PRINT-RESULT
           END-PERFORM
           PERFORM VARYING D FROM 1 BY 1 UNTIL D > MAX-DEGREE
               MOVE SPACES TO WS-NAME
               STRING "test_rmse_d" D DELIMITED BY SIZE INTO WS-NAME
               MOVE WS-TEST-ERROR(D) TO WS-RESULT
               PERFORM PRINT-RESULT
           END-PERFORM

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

      *> Store one drive and count it as training or test.
       ADD-DRIVE.
           PERFORM SPLIT-LINE
           ADD 1 TO WS-N
           COMPUTE WS-SPEED(WS-N) =
               FUNCTION NUMVAL(WS-FIELD(WS-SPEED-COL))
           COMPUTE WS-Y(WS-N) =
               FUNCTION NUMVAL(WS-FIELD(WS-LITRES-COL))
           IF WS-FIELD(WS-SPLIT-COL) = "train"
               MOVE "Y" TO WS-IS-TRAIN(WS-N)
               ADD 1 TO WS-TRAIN-COUNT
           ELSE
               MOVE "N" TO WS-IS-TRAIN(WS-N)
               ADD 1 TO WS-TEST-COUNT
           END-IF.

      *> Map the training speeds onto -1 to 1. Raw speeds to the 16th
      *> power (the largest entry at degree 8) would swamp the small
      *> ones and need far more digits. The test speeds use the same
      *> training range.
       SCALE-SPEEDS.
           MOVE 999999 TO WS-LOW
           MOVE -999999 TO WS-HIGH
           PERFORM VARYING S FROM 1 BY 1 UNTIL S > WS-N
               IF WS-IS-TRAIN(S) = "Y"
                   IF WS-SPEED(S) < WS-LOW
                       MOVE WS-SPEED(S) TO WS-LOW
                   END-IF
                   IF WS-SPEED(S) > WS-HIGH
                       MOVE WS-SPEED(S) TO WS-HIGH
                   END-IF
               END-IF
           END-PERFORM
           COMPUTE WS-MID = (WS-LOW + WS-HIGH) / 2
           COMPUTE WS-HALF = (WS-HIGH - WS-LOW) / 2
           PERFORM VARYING S FROM 1 BY 1 UNTIL S > WS-N
               COMPUTE WS-Z(S) ROUNDED =
                   (WS-SPEED(S) - WS-MID) / WS-HALF
           END-PERFORM.

      *> Least squares: the coefficients solve (Z^T Z) c = Z^T y, so
      *> entry (I, J) sums z^(I+J-2) over the training drives, and the
      *> last column sums y z^(I-1). Each drive's powers come from
      *> repeated multiplication.
       BUILD-SYSTEM.
           MOVE ZEROS TO WS-A-TABLE
           PERFORM VARYING S FROM 1 BY 1 UNTIL S > WS-N
               IF WS-IS-TRAIN(S) = "Y"
                   MOVE 1 TO WS-POW(1)
                   PERFORM VARYING I FROM 2 BY 1 UNTIL I > 2 * N - 1
                       COMPUTE WS-POW(I) ROUNDED =
                           WS-POW(I - 1) * WS-Z(S)
                   END-PERFORM
                   PERFORM VARYING I FROM 1 BY 1 UNTIL I > N
                       PERFORM VARYING J FROM 1 BY 1 UNTIL J > N
                           ADD WS-POW(I + J - 1) TO WS-A(I, J)
                       END-PERFORM
                       COMPUTE WS-A(I, N + 1) ROUNDED =
                           WS-A(I, N + 1) + WS-Y(S) * WS-POW(I)
                   END-PERFORM
               END-IF
           END-PERFORM.

      *> Gaussian elimination with partial pivoting, then back
      *> substitution into WS-X.
       SOLVE.
           PERFORM VARYING K FROM 1 BY 1 UNTIL K > N
      *>       Swap up the row with the largest entry in column K, which
      *>       keeps the rounding error small. Three group MOVEs swap
      *>       the rows through a spare one.
               MOVE K TO PIVOT
               PERFORM VARYING R FROM K BY 1 UNTIL R > N
                   IF FUNCTION ABS(WS-A(R, K))
                           > FUNCTION ABS(WS-A(PIVOT, K))
                       MOVE R TO PIVOT
                   END-IF
               END-PERFORM
               MOVE WS-A-ROW(K) TO WS-SPARE-ROW
               MOVE WS-A-ROW(PIVOT) TO WS-A-ROW(K)
               MOVE WS-SPARE-ROW TO WS-A-ROW(PIVOT)
      *>       Each lower row subtracts the multiple of row K that
      *>       clears its entry in column K.
               PERFORM VARYING R FROM K BY 1 UNTIL R > N
                   IF R > K
                       COMPUTE WS-FACTOR ROUNDED =
                           WS-A(R, K) / WS-A(K, K)
                       PERFORM VARYING C FROM K BY 1 UNTIL C > N + 1
                           COMPUTE WS-A(R, C) ROUNDED =
                               WS-A(R, C) - WS-FACTOR * WS-A(K, C)
                       END-PERFORM
                   END-IF
               END-PERFORM
           END-PERFORM
      *>   Back substitution, from the last unknown up.
           PERFORM VARYING R FROM N BY -1 UNTIL R < 1
               MOVE WS-A(R, N + 1) TO WS-SUM
               PERFORM VARYING C FROM R BY 1 UNTIL C > N
                   IF C > R
                       COMPUTE WS-SUM ROUNDED =
                           WS-SUM - WS-A(R, C) * WS-X(C)
                   END-IF
               END-PERFORM
               COMPUTE WS-X(R) ROUNDED = WS-SUM / WS-A(R, R)
           END-PERFORM.

      *> Root-mean-square error of the current fit over the drives
      *> whose WS-IS-TRAIN matches WS-WHICH.
       MEASURE-RMSE.
           MOVE 0 TO WS-SUM
           MOVE 0 TO WS-COUNT
           PERFORM VARYING S FROM 1 BY 1 UNTIL S > WS-N
               IF WS-IS-TRAIN(S) = WS-WHICH
                   ADD 1 TO WS-COUNT
                   MOVE 0 TO WS-PREDICTED
                   MOVE 1 TO WS-POWER
                   PERFORM VARYING I FROM 1 BY 1 UNTIL I > N
                       COMPUTE WS-PREDICTED ROUNDED =
                           WS-PREDICTED + WS-X(I) * WS-POWER
                       COMPUTE WS-POWER ROUNDED = WS-POWER * WS-Z(S)
                   END-PERFORM
                   COMPUTE WS-SUM ROUNDED =
                       WS-SUM + (WS-PREDICTED - WS-Y(S)) ** 2
               END-IF
           END-PERFORM
           COMPUTE WS-RMSE ROUNDED =
               FUNCTION SQRT(WS-SUM / WS-COUNT).

      *> Print "name value", rounded to six decimal places.
       PRINT-RESULT.
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY FUNCTION TRIM(WS-NAME) " "
               FUNCTION TRIM(WS-RESULT-OUT).
