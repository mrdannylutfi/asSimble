       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2MRGBT.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO UT-S-INFILE.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE
           RECORD CONTAINS 100 CHARACTERS.  *> Define fixed-length FB 100 bytes
       01  IN-RECORD.
           05  IN-EMP-ID       PIC X(10).
           05  IN-EMP-NAME     PIC X(30).
           05  IN-SALARY       PIC S9(7)V99 COMP-3.
           05  FILLER          PIC X(55).        *> Pad to 100 bytes

       WORKING-STORAGE SECTION.
       *---- DB2 Host variable array definition (Batch buffer of 100 items) ----
       01  DB-ARRAY-SIZE       CONSTANT AS 100.
       
       01  HOST-ARRAYS.
           05  H-EMP-ID        PIC X(10) OCCURS 100 TIMES.
           05  H-EMP-NAME      PIC X(30) OCCURS 100 TIMES.
           05  H-SALARY        PIC S9(7)V99 COMP-3 OCCURS 100 TIMES.

       *---- Counters and control variables ----
       01  WS-COUNTERS.
           05  ARRAY-IDX       PIC S9(4) COMP VALUE 1.
           05  WS-TOTAL-ROWS   PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-COMMIT-ROWS  PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-COMMIT-LIMIT PIC S9(9) COMP-3 VALUE 10000.
           05  EOF-FLAG        PIC X(01) VALUE 'N'.

       *---- Db2 通用 SQLCA ----
       EXEC SQL INCLUDE SQLCA END-EXEC.

       PROCEDURE DIVISION.
       A000-MAIN.
           OPEN INPUT IN-FILE.
           
           PERFORM UNTIL EOF-FLAG = 'Y'
               READ IN-FILE
                   AT END
                       MOVE 'Y' TO EOF-FLAG
                   NOT AT END
                       *Move data into a batch array.
                       MOVE IN-EMP-ID   TO H-EMP-ID(ARRAY-IDX)
                       MOVE IN-EMP-NAME TO H-EMP-NAME(ARRAY-IDX)
                       MOVE IN-SALARY   TO H-SALARY(ARRAY-IDX)
                       
                       * High-performance MERGE is triggered when the array reaches 100 entries.
                       IF ARRAY-IDX = DB-ARRAY-SIZE
                           PERFORM C000-BULK-MERGE
                           MOVE 1 TO ARRAY-IDX
                       ELSE
                           ADD 1 TO ARRAY-IDX
                       END-IF
               END-READ
           END-PERFORM.

           * Process the remaining trailing items in the array—fewer than 100 in total.
           IF ARRAY-IDX > 1
               SUBTRACT 1 FROM ARRAY-IDX
               PERFORM C000-BULK-MERGE
           END-IF.

           *Final concluding commit
           EXEC SQL COMMIT END-EXEC.
           CLOSE IN-FILE.
           DISPLAY 'TOTAL PROCESSED: ' WS-TOTAL-ROWS ' ROWS.'.
           GOBACK.

       C000-BULK-MERGE.
           *ARRAY-IDX dynamically represents the actual number of rows currently being passed to D
           EXEC SQL
               FOR :ARRAY-IDX ROWS
               MERGE INTO EMPLOYEE AS T
               USING (VALUES(:H-EMP-ID, :H-EMP-NAME, :H-SALARY)) 
                     AS S (EMP_ID, EMP_NAME, SALARY)
               ON (T.EMP_ID = S.EMP_ID)
               WHEN MATCHED THEN
                   UPDATE SET T.EMP_NAME = S.EMP_NAME,
                              T.SALARY   = S.SALARY
               WHEN NOT MATCHED THEN
                   INSERT (EMP_ID, EMP_NAME, SALARY)
                   VALUES (S.EMP_ID, S.EMP_NAME, S.SALARY)
           END-EXEC.

           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100
               DISPLAY 'DB2 MERGE ERROR, SQLCODE: ' SQLCODE
               PERFORM Z999-ABEND
           END-IF.

           *Accumulate: Global and intermittent counters 
           ADD ARRAY-IDX TO WS-TOTAL-ROWS
           ADD ARRAY-IDX TO WS-COMMIT-ROWS

           *Trigger an intermittent COMMIT every 10,000 records to prevent the log from filling up.
           IF WS-COMMIT-ROWS >= WS-COMMIT-LIMIT
               EXEC SQL COMMIT END-EXEC
               IF SQLCODE NOT = 0
                   DISPLAY 'COMMIT ERROR, SQLCODE: ' SQLCODE
                   PERFORM Z999-ABEND
               END-IF
               MOVE ZERO TO WS-COMMIT-ROWS
               DISPLAY 'INTERMITTENT COMMIT PASSED AT: ' WS-TOTAL-ROWS
           END-IF.

       Z999-ABEND.
           EXEC SQL ROLLBACK END-EXEC.
           CLOSE IN-FILE.
           CALL 'ILBOABN0' USING BY VALUE 999.
