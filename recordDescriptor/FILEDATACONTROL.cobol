       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMP-FILE ASSIGN TO UT-S-EMPIN
               FILE STATUS IS WS-FILE-STATUS.
           SELECT ERR-FILE ASSIGN TO UT-S-ERRFILE
               FILE STATUS IS WS-ERR-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  EMP-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  EMP-RECORD.
           05 IN-ID            PIC X(100).
           05 IN-NAME          PIC X(200).
           05 IN-WAGE          PIC X(100).
           05 IN-STREET        PIC X(100).
           05 IN-TELEPHONE     PIC X(100).
      *    FILLER TO EXPAND RECORD STORAGE TO FULL 2,000,000 LRECL
           05 FILLER           PIC X(1999400).

       FD  ERR-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  ERR-RECORD.
           05 ERR-MSG          PIC X(50).
           05 ERR-DATA-ID      PIC X(100).
           05 FILLER           PIC X(1999850).
