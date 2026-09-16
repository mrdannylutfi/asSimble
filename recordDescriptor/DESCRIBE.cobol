       ENVIRONMENT DIVISION.
       FILE-CONTROL.
           SELECT EMP-FILE ASSIGN TO UT-S-EMPIN
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  EMP-FILE
           RECORDING MODE IS V
           RECORD IS VARYING FROM 50 TO 250 CHARACTERS
           DEPENDING ON WS-CURRENT-REC-LEN.
       01  EMP-RECORD.
           05 IN-EMP-ID        PIC 9(05).
           05 IN-EMP-NAME      PIC X(30).
           * Rest of your fields go here...
           
       WORKING-STORAGE SECTION.
       01  WS-CURRENT-REC-LEN  PIC 9(04) COMP.
