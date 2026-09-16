      ******************************************************************
      * TARGET DB2 TABLE HOST STRUCTURES
      ******************************************************************
       01  H-EMPLOYEE-RECORD.
           05 H-ID             PIC S9(9)      COMP-5.
           
           05 H-EMP-NAME.
              49 H-NAME-LEN    PIC S9(4)      COMP.
              49 H-NAME-TEXT   PIC X(30).
              
           05 H-WAGE           USAGE COMP-2.
           
           05 H-STREET.
              49 H-STR-LEN     PIC S9(4)      COMP.
              49 H-STR-TEXT    PIC X(50).
              
           05 H-TELEPHONE      PIC S9(15)     COMP-3.

      ******************************************************************
      * DB2 NULL INDICATORS (S9(4) COMP Required for every nullable column)
      ******************************************************************
       01  H-NULL-INDICATORS.
           05 NI-STREET        PIC S9(4)      COMP.
              88 STR-IS-NULL                  VALUE -1.
              88 STR-NOT-NULL                 VALUE 0.
           05 NI-TELEPHONE     PIC S9(4)      COMP.
              88 TEL-IS-NULL                  VALUE -1.
              88 TEL-NOT-NULL                 VALUE 0.
