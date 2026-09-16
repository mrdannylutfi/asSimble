       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2BATCH.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO UT-S-INFILE.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-RECORD.
           05  IN-EMP-ID       PIC X(10).
           05  IN-EMP-NAME     PIC X(30).
           05  IN-SALARY       PIC S9(7)V99 COMP-3.

       WORKING-STORAGE SECTION.
       *---- DB2 宿主变量数组定义 (每次批量处理 100 条) ----
       01  DB-ARRAY-SIZE       CONSTANT AS 100.
       
       01  HOST-ARRAYS.
           05  H-EMP-ID        PIC X(10) OCCURS 100 TIMES.
           05  H-EMP-NAME      PIC X(30) OCCURS 100 TIMES.
           05  H-SALARY        PIC S9(7)V99 COMP-3 OCCURS 100 TIMES.

       *---- 计数器与控制变量 ----
       01  WS-COUNTERS.
           05  ARRAY-IDX       PIC S9(4) COMP VALUE 1.
           05  WS-TOTAL-ROWS   PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-COMMIT-ROWS  PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-COMMIT-LIMIT PIC S9(9) COMP-3 VALUE 10000.
           05  EOF-FLAG        PIC X(01) VALUE 'N'.

       *---- Db2 诊断区域 (用于获取批量处理中具体哪行出错) ----
       EXEC SQL INCLUDE SQLCA END-EXEC.

       PROCEDURE DIVISION.
       A000-MAIN.
           OPEN INPUT IN-FILE.
           
           PERFORM UNTIL EOF-FLAG = 'Y'
               READ IN-FILE
                   AT END
                       MOVE 'Y' TO EOF-FLAG
                   NOT AT END
                       * 将数据移入内存数组
                       MOVE IN-EMP-ID   TO H-EMP-ID(ARRAY-IDX)
                       MOVE IN-EMP-NAME TO H-EMP-NAME(ARRAY-IDX)
                       MOVE IN-SALARY   TO H-SALARY(ARRAY-IDX)
                       
                       * 数组写满 100 条，触发批量写入
                       IF ARRAY-IDX = DB-ARRAY-SIZE
                           PERFORM C000-BULK-INSERT
                           MOVE 1 TO ARRAY-IDX
                       ELSE
                           ADD 1 TO ARRAY-IDX
                       END-IF
               END-READ
           END-PERFORM.

           * 处理最后留在数组中未满 100 条的残余数据
           IF ARRAY-IDX > 1
               SUBTRACT 1 FROM ARRAY-IDX
               PERFORM C000-BULK-INSERT
           END-IF.

           * 最终提交
           EXEC SQL COMMIT END-EXEC.
           CLOSE IN-FILE.
           GOBACK.

       C000-BULK-INSERT.
           * ARRAY-IDX 代表当前实际要写入的行数（通常是 100，最后一次可能小于 100）
           EXEC SQL
               FOR :ARRAY-IDX ROWS
               INSERT INTO EMPLOYEE (EMP_ID, EMP_NAME, SALARY)
               VALUES (:H-EMP-ID, :H-EMP-NAME, :H-SALARY)
           END-EXEC.

           IF SQLCODE NOT = 0 AND SQLCODE NOT = 100
               * [此处编写您的错误日志记录，SQLERRD(3) 会指出停在第几行]
               DISPLAY 'DB2 ERROR IN BATCH, SQLCODE: ' SQLCODE
               PERFORM Z999-ABEND
           END-IF.

           * 累加全局计数器
           ADD ARRAY-IDX TO WS-TOTAL-ROWS
           ADD ARRAY-IDX TO WS-COMMIT-ROWS

           * 每达到 10,000 条，执行一次事务提交并释放锁
           IF WS-COMMIT-ROWS >= WS-COMMIT-LIMIT
               EXEC SQL COMMIT END-EXEC
               IF SQLCODE NOT = 0
                   DISPLAY 'COMMIT ERROR, SQLCODE: ' SQLCODE
                   PERFORM Z999-ABEND
               END-IF
               MOVE ZERO TO WS-COMMIT-ROWS
               DISPLAY 'SUCCESSFULLY COMMITTED ' WS-TOTAL-ROWS ' ROWS.'
           END-IF.

       Z999-ABEND.
           EXEC SQL ROLLBACK END-EXEC.
           CLOSE IN-FILE.
           CALL 'ILBOABN0' USING BY VALUE 999. * 强制大机作业异常终止(Abend)
