       DATA DIVISION.
       WORKING-STORAGE SECTION.
       ....
       *---- Core control variables ----
       01  WS-COUNTERS.
           05  WS-RECORD-COUNT     PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-COMMIT-COUNT     PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-COMMIT-LIMIT     PIC S9(9) COMP-3 VALUE 5000.

       *---- SQL 游标声明 (必须带 WITH HOLD) ----
       EXEC SQL
           DECLARE MY_CURSOR CURSOR WITH HOLD FOR
           SELECT COL1, COL2 FROM MY_TABLE
           WHERE PROCESS_FLAG = 'N'
       END-EXEC.

       PROCEDITION DIVISION.
       A000-MAIN.
           EXEC SQL OPEN MY_CURSOR END-EXEC.
           PERFORM B000-PROCESS-LOOP UNTIL SQLCODE = 100.
           
           Finally, wrap up and submit the remaining data.
           EXEC SQL COMMIT END-EXEC.
           EXEC SQL CLOSE MY_CURSOR END-EXEC.
           GOBACK.

       B000-PROCESS-LOOP.
           EXEC SQL 
               FETCH MY_CURSOR INTO :DB-COL1, :DB-COL2 
           END-EXEC.

           IF SQLCODE = 0
                [Handle your business logic or execution here. INSERT/UPDATE]
               
                Counter increment
               ADD 1 TO WS-RECORD-COUNT
               ADD 1 TO WS-COMMIT-COUNT
               
               Trigger intermittent commits
               IF WS-COMMIT-COUNT >= WS-COMMIT-LIMIT
                   EXEC SQL COMMIT END-EXEC
                   IF SQLCODE NOT = 0
                       Error handling logic
                   END-IF
                   MOVE ZERO TO WS-COMMIT-COUNT
               END-IF
           END-IF.
