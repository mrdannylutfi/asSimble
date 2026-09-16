       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO UT-S-INFILE.

       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE
           * <-- 声明文件长度是变长的
           RECORD IS VARYING FROM 50 TO 200 CHARACTERS
           DEPENDING ON WS-CURRENT-REC-LEN.
       01  IN-RECORD.
           05  IN-EMP-ID       PIC X(10).
           * 后续字段可能是变长文本，这里定义最大上限
           05  IN-VAR-DATA     PIC X(190). 

       WORKING-STORAGE SECTION.
       *---- 系统会自动将当前读取到的物理行长度填入此变量 ----
       01  WS-CURRENT-REC-LEN  PIC S9(4) COMP.
