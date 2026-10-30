      *> k-means clustering (Lloyd's algorithm), in COBOL.
      *>
      *> Starts from the first K = 3 points as centroids, then alternates
      *> two steps until no point changes cluster: assign each point to
      *> its nearest centroid, and move each centroid to the mean of its
      *> points.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. K-MEANS.

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
       01  WS-K                     PIC 9 VALUE 3.
       01  WS-MAX-ITERATIONS        PIC 999 VALUE 100.
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

      *> The points, each with the cluster it is currently assigned to.
       01  WS-N                     PIC 9(4) VALUE 0.
       01  WS-POINTS.
           05  WS-POINT             OCCURS 5000 TIMES.
               10  WS-X             PIC S9(9)V9(6).
               10  WS-Y             PIC S9(9)V9(6).
               10  WS-CLUSTER       PIC 9 VALUE 0.

      *> The centroids, with the sums and sizes used to move them.
       01  WS-CENTROIDS.
           05  WS-CENTROID          OCCURS 9 TIMES.
               10  WS-CX            PIC S9(9)V9(12).
               10  WS-CY            PIC S9(9)V9(12).
               10  WS-SUM-X         PIC S9(12)V9(6).
               10  WS-SUM-Y         PIC S9(12)V9(6).
               10  WS-SIZE          PIC 9(4).

       01  I                        PIC 9(4).
       01  J                        PIC 99.
       01  WS-NEAREST               PIC 9.
       01  WS-DIST                  PIC S9(12)V9(12).
       01  WS-BEST-DIST             PIC S9(12)V9(12).
       01  WS-ITERATIONS            PIC 999 VALUE 0.
       01  WS-CHANGED               PIC X.
           88  ASSIGNMENT-CHANGED   VALUE "Y".
       01  WS-INERTIA               PIC S9(12)V9(12) VALUE 0.

      *> Output: a name, then the value edited to six decimal places.
       01  WS-NAME                  PIC X(20).
       01  WS-RESULT                PIC S9(12)V9(12).
       01  WS-RESULT-OUT            PIC -(12)9.9(6).
       01  WS-COUNT-OUT             PIC Z(8)9.
       01  WS-INDEX-OUT             PIC Z9.

       PROCEDURE DIVISION.
       MAIN.
           ACCEPT WS-FILE-NAME FROM ARGUMENT-VALUE
           OPEN INPUT DATA-FILE

           READ DATA-FILE
               AT END SET END-OF-FILE TO TRUE
           END-READ
           PERFORM SPLIT-LINE
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-FIELD-COUNT
               IF WS-FIELD(I) = "x"
                   MOVE I TO WS-X-COLUMN
               END-IF
               IF WS-FIELD(I) = "y"
                   MOVE I TO WS-Y-COLUMN
               END-IF
           END-PERFORM
           IF WS-X-COLUMN = 0 OR WS-Y-COLUMN = 0
               DISPLAY "missing column x or y" UPON SYSERR
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

      *>   The first K points are the starting centroids.
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > WS-K
               MOVE WS-X(J) TO WS-CX(J)
               MOVE WS-Y(J) TO WS-CY(J)
           END-PERFORM

      *>   Every assignment pass counts, including the final one that
      *>   changes nothing.
           MOVE "Y" TO WS-CHANGED
           PERFORM UNTIL NOT ASSIGNMENT-CHANGED
                   OR WS-ITERATIONS >= WS-MAX-ITERATIONS
               ADD 1 TO WS-ITERATIONS
               PERFORM ASSIGN-POINTS
               IF ASSIGNMENT-CHANGED
                   PERFORM MOVE-CENTROIDS
               END-IF
           END-PERFORM

      *>   Inertia: the sum of squared distances to assigned centroids.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               MOVE WS-CLUSTER(I) TO J
               PERFORM DISTANCE
               ADD WS-DIST TO WS-INERTIA
           END-PERFORM

           MOVE WS-ITERATIONS TO WS-COUNT-OUT
           DISPLAY "iterations " FUNCTION TRIM(WS-COUNT-OUT)
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > WS-K
               MOVE J TO WS-INDEX-OUT
               MOVE SPACES TO WS-NAME
               STRING "centroid_" FUNCTION TRIM(WS-INDEX-OUT) "_x"
                   DELIMITED BY SIZE INTO WS-NAME
               MOVE WS-CX(J) TO WS-RESULT
               PERFORM PRINT-RESULT
               MOVE SPACES TO WS-NAME
               STRING "centroid_" FUNCTION TRIM(WS-INDEX-OUT) "_y"
                   DELIMITED BY SIZE INTO WS-NAME
               MOVE WS-CY(J) TO WS-RESULT
               PERFORM PRINT-RESULT
           END-PERFORM
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > WS-K
               MOVE J TO WS-INDEX-OUT
               MOVE WS-SIZE(J) TO WS-COUNT-OUT
               DISPLAY "size_" FUNCTION TRIM(WS-INDEX-OUT) " "
                   FUNCTION TRIM(WS-COUNT-OUT)
           END-PERFORM
           MOVE "inertia" TO WS-NAME
           MOVE WS-INERTIA TO WS-RESULT
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

      *> Store one data line's point.
       ADD-POINT.
           PERFORM SPLIT-LINE
           ADD 1 TO WS-N
           COMPUTE WS-X(WS-N) = FUNCTION NUMVAL(WS-FIELD(WS-X-COLUMN))
           COMPUTE WS-Y(WS-N) = FUNCTION NUMVAL(WS-FIELD(WS-Y-COLUMN)).

      *> Squared distance from point I to centroid J, into WS-DIST.
      *> Squared distance picks the same nearest centroid as distance.
       DISTANCE.
           COMPUTE WS-DIST = (WS-X(I) - WS-CX(J)) ** 2
                           + (WS-Y(I) - WS-CY(J)) ** 2.

      *> Assign every point to its nearest centroid; note any change.
       ASSIGN-POINTS.
           MOVE "N" TO WS-CHANGED
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               MOVE 1 TO WS-NEAREST
               MOVE 1 TO J
               PERFORM DISTANCE
               MOVE WS-DIST TO WS-BEST-DIST
      *>       A strict "<" sends a tie to the lower centroid index.
               PERFORM VARYING J FROM 2 BY 1 UNTIL J > WS-K
                   PERFORM DISTANCE
                   IF WS-DIST < WS-BEST-DIST
                       MOVE J TO WS-NEAREST
                       MOVE WS-DIST TO WS-BEST-DIST
                   END-IF
               END-PERFORM
               IF WS-NEAREST NOT = WS-CLUSTER(I)
                   MOVE WS-NEAREST TO WS-CLUSTER(I)
                   MOVE "Y" TO WS-CHANGED
               END-IF
           END-PERFORM.

      *> Move each centroid to the mean of its points. An empty cluster
      *> keeps its old centroid.
       MOVE-CENTROIDS.
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > WS-K
               MOVE 0 TO WS-SUM-X(J) WS-SUM-Y(J) WS-SIZE(J)
           END-PERFORM
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > WS-N
               MOVE WS-CLUSTER(I) TO J
               ADD WS-X(I) TO WS-SUM-X(J)
               ADD WS-Y(I) TO WS-SUM-Y(J)
               ADD 1 TO WS-SIZE(J)
           END-PERFORM
           PERFORM VARYING J FROM 1 BY 1 UNTIL J > WS-K
               IF WS-SIZE(J) > 0
                   COMPUTE WS-CX(J) ROUNDED = WS-SUM-X(J) / WS-SIZE(J)
                   COMPUTE WS-CY(J) ROUNDED = WS-SUM-Y(J) / WS-SIZE(J)
               END-IF
           END-PERFORM.

      *> Print "name value", rounded to six decimal places.
       PRINT-RESULT.
           COMPUTE WS-RESULT-OUT ROUNDED = WS-RESULT
           DISPLAY FUNCTION TRIM(WS-NAME) " "
               FUNCTION TRIM(WS-RESULT-OUT).
