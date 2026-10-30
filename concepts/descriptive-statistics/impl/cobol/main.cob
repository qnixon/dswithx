      *> Descriptive statistics on one CSV column, in COBOL.
      *>
      *> COBOL has had MEAN, MEDIAN, VARIANCE, and STANDARD-DEVIATION
      *> intrinsic functions since 1989; they are avoided here so the
      *> arithmetic stays visible.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DESCRIPTIVE-STATISTICS.

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
       01  WS-COLUMN-NAME           PIC X(40) VALUE "minutes".
       01  WS-EOF                   PIC X VALUE "N".
           88  END-OF-FILE          VALUE "Y".

      *> One CSV line split into fields, and where the column is.
       01  WS-FIELDS.
           05  WS-FIELD             PIC X(40) OCCURS 20 TIMES.
       01  WS-FIELD-COUNT           PIC 99.
       01  WS-POINTER               PIC 999.
       01  WS-LINE-LENGTH           PIC 999.
       01  WS-COLUMN                PIC 99 VALUE 0.

      *> The values: fixed-point decimals, 9 digits before the point
      *> and 6 after.
       01  WS-N                     PIC 9(4) VALUE 0.
       01  WS-VALUES.
           05  WS-VALUE             PIC S9(9)V9(6)
                                    OCCURS 1 TO 5000 TIMES
                                    DEPENDING ON WS-N.

       01  I                        PIC 9(4).
       01  WS-MIDDLE                PIC 9(4).
       01  WS-REMAINDER             PIC 9.
       01  WS-SUM                   PIC S9(12)V9(6) VALUE 0.
       01  WS-MEAN                  PIC S9(9)V9(12).
       01  WS-MEDIAN                PIC S9(9)V9(6).
       01  WS-SQUARES               PIC S9(12)V9(12) VALUE 0.
       01  WS-VARIANCE              PIC S9(9)V9(12).
       01  WS-STD-DEV               PIC S9(9)V9(12).

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
               IF WS-FIELD(I) = WS-COLUMN-NAME
                   MOVE I TO WS-COLUMN
               END-IF
           END-PERFORM
           IF WS-COLUMN = 0
               DISPLAY "no column " FUNCTION TRIM(WS-COLUMN-NAME)
                   UPON SYSERR
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM UNTIL END-OF-FILE
               READ DATA-FILE
                   AT END SET END-OF-FILE TO TRUE
                   NOT AT END PERFORM ADD-VALUE
               END-READ
           END-PERFORM
           CLOSE DATA-FILE

      *>   SORT works on tables in working storage, not just files.
           SORT WS-VALUE ASCENDING

           COMPUTE WS-MEAN ROUNDED = WS-SUM / WS-N

           DIVIDE WS-N BY 2 GIVING WS-MIDDLE REMAINDER WS-REMAINDER
           IF WS-REMAINDER = 1
               MOVE WS-VALUE(WS-MIDDLE + 1) TO WS-MEDIAN
           ELSE
               COMPUTE WS-MEDIAN ROUNDED =
                   (WS-VALUE(WS-MIDDLE) + WS-VALUE(WS-MIDDLE + 1)) / 2
           END-IF

      *>   Sample variance divides by n - 1, not n (Bessel's correction).
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               COMPUTE WS-SQUARES =
                   WS-SQUARES + (WS-VALUE(I) - WS-MEAN) ** 2
           END-PERFORM
           COMPUTE WS-VARIANCE ROUNDED = WS-SQUARES / (WS-N - 1)
           COMPUTE WS-STD-DEV ROUNDED = FUNCTION SQRT(WS-VARIANCE)

           MOVE WS-N TO WS-COUNT-OUT
           DISPLAY "count " FUNCTION TRIM(WS-COUNT-OUT)
           MOVE "sum" TO WS-NAME
           MOVE WS-SUM TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "mean" TO WS-NAME
           MOVE WS-MEAN TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "median" TO WS-NAME
           MOVE WS-MEDIAN TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "min" TO WS-NAME
           MOVE WS-VALUE(1) TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "max" TO WS-NAME
           MOVE WS-VALUE(WS-N) TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "range" TO WS-NAME
           COMPUTE WS-RESULT = WS-VALUE(WS-N) - WS-VALUE(1)
           PERFORM PRINT-RESULT
           MOVE "variance" TO WS-NAME
           MOVE WS-VARIANCE TO WS-RESULT
           PERFORM PRINT-RESULT
           MOVE "std_dev" TO WS-NAME
           MOVE WS-STD-DEV TO WS-RESULT
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

      *> Store one data line's value and add it to the running sum.
       ADD-VALUE.
           PERFORM SPLIT-LINE
           ADD 1 TO WS-N
           COMPUTE WS-VALUE(WS-N) = FUNCTION NUMVAL(WS-FIELD(WS-COLUMN))
           ADD WS-VALUE(WS-N) TO WS-SUM.

      *> Print "name value", rounded to six decimal places.
       PRINT-RESULT.
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY FUNCTION TRIM(WS-NAME) " "
               FUNCTION TRIM(WS-RESULT-OUT).
