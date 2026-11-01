      *> Principal component analysis by power iteration, in COBOL.
      *>
      *> Standardizes the four scores, builds their correlation matrix,
      *> and finds the top two eigenvectors (the principal components):
      *> power iteration finds the first, then deflation removes it from
      *> the matrix so the same steps find the second. Values are
      *> fixed-point decimals carried to 18 decimal places.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PCA.

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

      *> The four subjects, and which CSV column holds each one.
       01  WS-SUBJECT-NAMES.
           05  FILLER               PIC X(8) VALUE "math".
           05  FILLER               PIC X(8) VALUE "physics".
           05  FILLER               PIC X(8) VALUE "reading".
           05  FILLER               PIC X(8) VALUE "writing".
       01  WS-SUBJECTS REDEFINES WS-SUBJECT-NAMES.
           05  WS-SUBJECT           PIC X(8) OCCURS 4 TIMES.
       01  WS-COLUMNS.
           05  WS-COLUMN            PIC 99 VALUE 0 OCCURS 4 TIMES.
       01  K                        PIC 9 VALUE 4.

      *> Every student's four scores, standardized in place.
       01  WS-N                     PIC 9(4) VALUE 0.
       01  WS-ROWS.
           05  WS-ROW               OCCURS 5000 TIMES.
               10  WS-Z             PIC S9(6)V9(18) OCCURS 4 TIMES.

      *> Each column's mean and sample standard deviation.
       01  WS-STATS.
           05  WS-MEAN              PIC S9(6)V9(18) OCCURS 4 TIMES.
           05  WS-SD                PIC S9(6)V9(18) OCCURS 4 TIMES.
       01  WS-SUM                   PIC S9(9)V9(18).

      *> A 4 x 4 matrix is a table of rows, each a table of entries:
      *> WS-CORR(I, J). WS-M is the matrix power iteration works on.
       01  WS-CORR-TABLE.
           05  WS-CORR-ROW          OCCURS 4 TIMES.
               10  WS-CORR          PIC S9(3)V9(18) OCCURS 4 TIMES.
       01  WS-M-TABLE.
           05  WS-M-ROW             OCCURS 4 TIMES.
               10  WS-M             PIC S9(3)V9(18) OCCURS 4 TIMES.

      *> Power iteration's vector V, the product M V, and its length.
       01  WS-V-TABLE.
           05  WS-V                 PIC S9(3)V9(18) OCCURS 4 TIMES.
       01  WS-MV-TABLE.
           05  WS-MV                PIC S9(3)V9(18) OCCURS 4 TIMES.
       01  WS-LENGTH                PIC S9(3)V9(18).
       01  WS-EIGENVALUE            PIC S9(3)V9(18).
       01  WS-STEPS                 PIC 9(4) VALUE 1000.

      *> The two components found: eigenvalues and eigenvectors.
       01  WS-PC-TABLE.
           05  WS-PC                OCCURS 2 TIMES.
               10  WS-PC-VALUE      PIC S9(3)V9(18).
               10  WS-PC-VECTOR     PIC S9(3)V9(18) OCCURS 4 TIMES.

       01  I                        PIC 9(4).
       01  J                        PIC 9(4).
       01  C                        PIC 9.
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
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
                   IF WS-FIELD(I) = WS-SUBJECT(J)
                       MOVE I TO WS-COLUMN(J)
                   END-IF
               END-PERFORM
           END-PERFORM
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
               IF WS-COLUMN(J) = 0
                   DISPLAY "missing column" UPON SYSERR
                   MOVE 1 TO RETURN-CODE
                   STOP RUN
               END-IF
           END-PERFORM

           PERFORM UNTIL END-OF-FILE
               READ DATA-FILE
                   AT END SET END-OF-FILE TO TRUE
                   NOT AT END PERFORM ADD-ROW
               END-READ
           END-PERFORM
           CLOSE DATA-FILE

           PERFORM STANDARDIZE

      *>   The correlation matrix: the covariance of the standardized
      *>   columns.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > K
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
                   MOVE 0 TO WS-SUM
                   PERFORM VARYING S FROM 1 BY 1 UNTIL S > WS-N
                       COMPUTE WS-SUM ROUNDED =
                           WS-SUM + WS-Z(S, I) * WS-Z(S, J)
                   END-PERFORM
                   COMPUTE WS-CORR(I, J) ROUNDED = WS-SUM / (WS-N - 1)
               END-PERFORM
           END-PERFORM

           MOVE WS-CORR-TABLE TO WS-M-TABLE
           MOVE 1 TO C
           PERFORM TOP-EIGENVECTOR

      *>   Deflation: subtract the first component's share, leaving the
      *>   rest.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > K
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
                   COMPUTE WS-M(I, J) ROUNDED = WS-CORR(I, J)
                       - WS-PC-VALUE(1) * WS-PC-VECTOR(1, I)
                         * WS-PC-VECTOR(1, J)
               END-PERFORM
           END-PERFORM
           MOVE 2 TO C
           PERFORM TOP-EIGENVECTOR

           MOVE WS-N TO WS-COUNT-OUT
           DISPLAY "count " FUNCTION TRIM(WS-COUNT-OUT)
           PERFORM VARYING C FROM 1 BY 1 UNTIL C > 2
               MOVE SPACES TO WS-NAME
               STRING "eigenvalue_" C DELIMITED BY SIZE INTO WS-NAME
               MOVE WS-PC-VALUE(C) TO WS-RESULT
               PERFORM PRINT-RESULT
      *>       Standardized columns each have variance 1, so the total
      *>       is K.
               MOVE SPACES TO WS-NAME
               STRING "explained_" C DELIMITED BY SIZE INTO WS-NAME
               COMPUTE WS-RESULT ROUNDED = WS-PC-VALUE(C) / K
               PERFORM PRINT-RESULT
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
                   MOVE SPACES TO WS-NAME
                   STRING "pc" C "_" WS-SUBJECT(J)
                       DELIMITED BY SPACE INTO WS-NAME
                   MOVE WS-PC-VECTOR(C, J) TO WS-RESULT
                   PERFORM PRINT-RESULT
               END-PERFORM
           END-PERFORM

      *>   The first student's scores along each component.
           PERFORM VARYING C FROM 1 BY 1 UNTIL C > 2
               MOVE 0 TO WS-SUM
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
                   COMPUTE WS-SUM ROUNDED =
                       WS-SUM + WS-Z(1, J) * WS-PC-VECTOR(C, J)
               END-PERFORM
               MOVE SPACES TO WS-NAME
               STRING "student_1_pc" C DELIMITED BY SIZE INTO WS-NAME
               MOVE WS-SUM TO WS-RESULT
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

      *> Store one student's four scores.
       ADD-ROW.
           PERFORM SPLIT-LINE
           ADD 1 TO WS-N
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
               COMPUTE WS-Z(WS-N, J) =
                   FUNCTION NUMVAL(WS-FIELD(WS-COLUMN(J)))
           END-PERFORM.

      *> Rescale each column to mean 0 and sample standard deviation 1
      *> (dividing by n - 1).
       STANDARDIZE.
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
               MOVE 0 TO WS-SUM
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
                   ADD WS-Z(I, J) TO WS-SUM
               END-PERFORM
               COMPUTE WS-MEAN(J) ROUNDED = WS-SUM / WS-N
               MOVE 0 TO WS-SUM
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
                   COMPUTE WS-SUM =
                       WS-SUM + (WS-Z(I, J) - WS-MEAN(J)) ** 2
               END-PERFORM
               COMPUTE WS-SD(J) ROUNDED =
                   FUNCTION SQRT(WS-SUM / (WS-N - 1))
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
                   COMPUTE WS-Z(I, J) ROUNDED =
                       (WS-Z(I, J) - WS-MEAN(J)) / WS-SD(J)
               END-PERFORM
           END-PERFORM.

      *> Power iteration on WS-M: multiply by the matrix and rescale,
      *> WS-STEPS times. Saves the eigenvalue and eigenvector as
      *> component C.
       TOP-EIGENVECTOR.
           MOVE 0 TO WS-V(2) WS-V(3) WS-V(4)
           MOVE 1 TO WS-V(1)
           PERFORM WS-STEPS TIMES
               PERFORM MULTIPLY-M-V
               MOVE 0 TO WS-SUM
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > K
                   COMPUTE WS-SUM ROUNDED = WS-SUM + WS-MV(I) ** 2
               END-PERFORM
               COMPUTE WS-LENGTH ROUNDED = FUNCTION SQRT(WS-SUM)
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > K
                   COMPUTE WS-V(I) ROUNDED = WS-MV(I) / WS-LENGTH
               END-PERFORM
           END-PERFORM
      *>   An eigenvector can point either way; make its first entry
      *>   positive.
           IF WS-V(1) < 0
               PERFORM VARYING I FROM 1 BY 1 UNTIL I > K
                   COMPUTE WS-V(I) = - WS-V(I)
               END-PERFORM
           END-IF
      *>   The eigenvalue is the Rayleigh quotient V . (M V).
           PERFORM MULTIPLY-M-V
           MOVE 0 TO WS-SUM
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > K
               COMPUTE WS-SUM ROUNDED = WS-SUM + WS-V(I) * WS-MV(I)
           END-PERFORM
           MOVE WS-SUM TO WS-PC-VALUE(C)
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > K
               MOVE WS-V(I) TO WS-PC-VECTOR(C, I)
           END-PERFORM.

      *> WS-MV = WS-M times WS-V.
       MULTIPLY-M-V.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > K
               MOVE 0 TO WS-MV(I)
               PERFORM VARYING J FROM 1 BY 1 UNTIL J > K
                   COMPUTE WS-MV(I) ROUNDED =
                       WS-MV(I) + WS-M(I, J) * WS-V(J)
               END-PERFORM
           END-PERFORM.

      *> Print "name value", rounded to six decimal places.
       PRINT-RESULT.
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY FUNCTION TRIM(WS-NAME) " "
               FUNCTION TRIM(WS-RESULT-OUT).
