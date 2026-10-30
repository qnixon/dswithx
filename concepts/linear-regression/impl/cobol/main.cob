      *> Simple linear regression by least squares, in COBOL.
      *>
      *> Fits score = intercept + slope * hours from the sums of squared
      *> deviations and cross-products, all in fixed-point decimals.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LINEAR-REGRESSION.

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
       01  WS-X-NAME                PIC X(40) VALUE "hours".
       01  WS-Y-NAME                PIC X(40) VALUE "score".
       01  WS-EOF                   PIC X VALUE "N".
           88  END-OF-FILE          VALUE "Y".

      *> One CSV line split into fields, and where the columns are.
       01  WS-FIELDS.
           05  WS-FIELD             PIC X(40) OCCURS 20 TIMES.
       01  WS-FIELD-COUNT           PIC 99.
       01  WS-POINTER               PIC 999.
       01  WS-LINE-LENGTH           PIC 999.
       01  WS-X-COLUMN              PIC 99 VALUE 0.
       01  WS-Y-COLUMN              PIC 99 VALUE 0.

      *> The (x, y) pairs.
       01  WS-N                     PIC 9(4) VALUE 0.
       01  WS-POINTS.
           05  WS-POINT             OCCURS 5000 TIMES.
               10  WS-X             PIC S9(9)V9(6).
               10  WS-Y             PIC S9(9)V9(6).

      *> Intermediate results carry 12 decimal places.
       01  I                        PIC 9(4).
       01  WS-SUM-X                 PIC S9(12)V9(6) VALUE 0.
       01  WS-SUM-Y                 PIC S9(12)V9(6) VALUE 0.
       01  WS-MEAN-X                PIC S9(9)V9(12).
       01  WS-MEAN-Y                PIC S9(9)V9(12).
       01  WS-SXX                   PIC S9(12)V9(12) VALUE 0.
       01  WS-SYY                   PIC S9(12)V9(12) VALUE 0.
       01  WS-SXY                   PIC S9(12)V9(12) VALUE 0.
       01  WS-SLOPE                 PIC S9(9)V9(12).
       01  WS-INTERCEPT             PIC S9(9)V9(12).
       01  WS-R                     PIC S9(3)V9(12).

      *> Output: a name, then the value edited to six decimal places.
       01  WS-NAME                  PIC X(20).
       01  WS-RESULT                PIC S9(12)V9(12).
       01  WS-RESULT-OUT            PIC -(12)9.9(6).
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
               IF WS-FIELD(I) = WS-X-NAME
                   MOVE I TO WS-X-COLUMN
               END-IF
               IF WS-FIELD(I) = WS-Y-NAME
                   MOVE I TO WS-Y-COLUMN
               END-IF
           END-PERFORM
           IF WS-X-COLUMN = 0 OR WS-Y-COLUMN = 0
               DISPLAY "missing column hours or score" UPON SYSERR
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM UNTIL END-OF-FILE
               READ DATA-FILE
                   AT END SET END-OF-FILE TO TRUE
                   NOT AT END PERFORM ADD-POINT
               END-READ
           END-PERFORM
           CLOSE DATA-FILE

           COMPUTE WS-MEAN-X ROUNDED = WS-SUM-X / WS-N
           COMPUTE WS-MEAN-Y ROUNDED = WS-SUM-Y / WS-N

      *>   Sums of squared deviations and of cross-products.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               COMPUTE WS-SXX = WS-SXX + (WS-X(I) - WS-MEAN-X) ** 2
               COMPUTE WS-SYY = WS-SYY + (WS-Y(I) - WS-MEAN-Y) ** 2
               COMPUTE WS-SXY = WS-SXY
                   + (WS-X(I) - WS-MEAN-X) * (WS-Y(I) - WS-MEAN-Y)
           END-PERFORM

           COMPUTE WS-SLOPE ROUNDED = WS-SXY / WS-SXX
           COMPUTE WS-INTERCEPT ROUNDED =
               WS-MEAN-Y - WS-SLOPE * WS-MEAN-X
           COMPUTE WS-R ROUNDED =
               WS-SXY / FUNCTION SQRT(WS-SXX * WS-SYY)

           MOVE WS-N TO WS-COUNT-OUT
           DISPLAY "count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE "slope" TO WS-NAME
           MOVE WS-SLOPE TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "intercept" TO WS-NAME
           MOVE WS-INTERCEPT TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "r" TO WS-NAME
           MOVE WS-R TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "r_squared" TO WS-NAME
           COMPUTE WS-RESULT ROUNDED = WS-R * WS-R
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

      *> Store one data line's (x, y) and add them to the running sums.
       ADD-POINT.
           PERFORM SPLIT-LINE
           ADD 1 TO WS-N
           COMPUTE WS-X(WS-N) = FUNCTION NUMVAL(WS-FIELD(WS-X-COLUMN))
           COMPUTE WS-Y(WS-N) = FUNCTION NUMVAL(WS-FIELD(WS-Y-COLUMN))
           ADD WS-X(WS-N) TO WS-SUM-X
           ADD WS-Y(WS-N) TO WS-SUM-Y.

      *> Print "name value", rounded to six decimal places.
       PRINT-RESULT.
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY FUNCTION TRIM(WS-NAME) " "
               FUNCTION TRIM(WS-RESULT-OUT).
