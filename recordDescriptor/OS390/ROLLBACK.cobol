       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2MRGEX.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE  ASSIGN TO UT-S-INFILE.
           *---- Added: Error log output file----
           SELECT ERR-FILE ASSIGN TO UT-S-ERRFILE.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE   RECORD CONTAINS 100 CHARACTERS.
       01  IN-RECORD       PIC X(100).

       FD  ERR-FILE  RECORD CONTAINS 130 CHARACTERS.   *> Includes source data and the cause of the error.
       01  ERR-RECORD.
           05  ERR-SRC-DATA    PIC X(100).
           05  FILLER          PIC X(02) VALUE ' |'.
           05  ERR-SQLCODE     PIC S9(4) SIGN LEADING SEPARATE.
           05  FILLER          PIC X(02) VALUE ' |'.
           05  ERR-MSG         PIC X(22).

       WORKING-STORAGE SECTION.
       01  DB-ARRAY-SIZE       CONSTANT AS 100.
       
       *---- Host arrays and shadow arrays (used to look up original 
        file lines upon error) ----
       01  HOST-ARRAYS.
           05  H-EMP-ID        PIC X(10) OCCURS 100 TIMES.
           05  H-EMP-NAME      PIC X(30) OCCURS 100 TIMES.
           05  H-SALARY        PIC S9(7)V99 COMP-3 OCCURS 100 TIMES.
       01  SRC-LINE-ARRAY.
           05  H-SRC-RECORD    PIC X(100) OCCURS 100 TIMES.

       01  WS-COUNTERS.
           05  ARRAY-IDX       PIC S9(4) COMP VALUE 1.
           05  WS-TOTAL-ROWS   PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-COMMIT-ROWS  PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-COMMIT-LIMIT PIC S9(9) COMP-3 VALUE 10000.
           05  WS-ERROR-COUNT  PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-ERROR-INDEX  PIC S9(9) COMP.
           05  EOF-FLAG        PIC X(01) VALUE 'N'.

       EXEC SQL INCLUDE SQLCA END-EXEC.

       PROCEDURE DIVISION.
       A000-MAIN.
           OPEN INPUT IN-FILE
                OUTPUT ERR-FILE.
           
      * ... [Standard READ loop omitted here; only during HOST-ARRAYS population, ...]
      *      ...simultaneously store IN-RECORD into H-SRC-RECORD(ARRAY-IDX)] ...
           
           * Final wrap-up
           EXEC SQL COMMIT END-EXEC.
           CLOSE IN-FILE ERR-FILE.
           DISPLAY 'PROCESS COMPLETED. SUCCESS: ' WS-TOTAL-ROWS 
                   ' ERRORS LOGGED: ' WS-ERROR-COUNT.
           GOBACK.

       C000-BULK-MERGE.
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

           *----------------------------------------------------------*
           *  Industrial-grade fault tolerance and breakpoint control logic
           *----------------------------------------------------------*
           EVALUATE TRUE
               WHEN SQLCODE = 0 OR SQLCODE = 100
                   * All 100 items in the entire batch were successfully processed.
                   ADD ARRAY-IDX TO WS-TOTAL-ROWS
                   ADD ARRAY-IDX TO WS-COMMIT-ROWS

               WHEN SQLCODE = -243 OR SQLCODE = -904
                   * Scenario A: In the event of a deadlock or 
                   * resource unavailability (timeout)
                   This is a critical system-level failure; since these
            * 100 records were not persisted to disk, a ROLLBACK must be 
            * performed, followed by a safe, immediate exit.
                   DISPLAY 'CRITICAL DEADLOCK/TIMEOUT. SQLCODE: ' SQLCODE
                   PERFORM Z888-ROLLBACK-RETRY
                   PERFORM Z999-ABEND

               WHEN OTHER
                   *  Scenario B: Data-level errors (e.g., -407 NOT NULL
                *constraint violation, -530 foreign key violation, etc.)
                   * 1. Log bad data to an error file
                   MOVE SQLERRD(3) TO WS-ERROR-INDEX
                   
                   IF WS-ERROR-INDEX > 0 AND WS-ERROR-INDEX <= ARRAY-IDX
                       * 1. Log bad data to an error file
                       ADD 1 TO WS-ERROR-COUNT
                       MOVE H-SRC-RECORD(WS-ERROR-INDEX) TO ERR-SRC-DATA
                       MOVE SQLCODE                      TO ERR-SQLCODE
                       MOVE 'BAD RECORD DROPPED'         TO ERR-MSG
                       WRITE ERR-RECORD
                       
                       * 2. Precise partial rollback (undoing only the
                       * rows from the current batch of 100 that have 
                       *already been partially written, to prevent 
                       * data contamination)
                       EXEC SQL ROLLBACK END-EXEC
                       
                       * 3. Fall back to a single-record fault-tolerant 
                       * retry mechanism (clean the current array row by
                       * row and discard invalid rows)
                       PERFORM C100-SINGLE-ROW-RETRY
                   ELSE
                       * If even an invalid index cannot be caught,
                       * it's an undefined crash
                       DISPLAY 'UNEXPECTED BATCH ERROR. SQLCODE: ' SQLCODE
                       PERFORM Z888-ROLLBACK-RETRY
                       PERFORM Z999-ABEND
                   END-IF
           END-EVALUATE.

           * Intermittent release lock boundary validation
           IF WS-COMMIT-ROWS >= WS-COMMIT-LIMIT
               EXEC SQL COMMIT END-EXEC
               MOVE ZERO TO WS-COMMIT-ROWS
               DISPLAY 'COMMIT CHECKPOINT PASSED AT ROW: ' WS-TOTAL-ROWS
           END-IF.

       C100-SINGLE-ROW-RETRY.
           * Commit the 100 records currently in the buffer pool one by one, ensuring the 99 valid records are successfully stored in the database
           PERFORM VARYING ARRAY-IDX FROM 1 BY 1 
                   UNTIL ARRAY-IDX > DB-ARRAY-SIZE
               EXEC SQL
                   MERGE INTO EMPLOYEE AS T
                   USING (VALUES(:H-EMP-ID(ARRAY-IDX), 
                                 :H-EMP-NAME(ARRAY-IDX), 
                                 :H-SALARY(ARRAY-IDX))) 
                         AS S (EMP_ID, EMP_NAME, SALARY)
                   ON (T.EMP_ID = S.EMP_ID)
                   WHEN MATCHED THEN
                       UPDATE SET T.EMP_NAME = S.EMP_NAME,
                                  T.SALARY   = S.SALARY
                   WHEN NOT MATCHED THEN
                       INSERT (EMP_ID, EMP_NAME, SALARY)
                       VALUES (S.EMP_ID, S.EMP_NAME, S.SALARY)
               END-EXEC
               
               IF SQLCODE = 0
                   ADD 1 TO WS-TOTAL-ROWS
                   ADD 1 TO WS-COMMIT-ROWS
               ELSE
                   * If that problematic data record reappears during single-record execution, skip it directly; the ERRFILE entry for it has already been written 
                   DISPLAY 'SKIPPED KEY IN RETRY: ' H-EMP-ID(ARRAY-IDX)
               END-IF
           END-PERFORM.

       Z888-ROLLBACK-RETRY.
           EXEC SQL ROLLBACK END-EXEC.
           DISPLAY 'DATABASE WORK ROLLBACKED TO LAST CHECKPOINT.'.

       Z999-ABEND.
           CLOSE IN-FILE ERR-FILE.
           CALL 'ILBOABN0' USING BY VALUE 999.
