      ******************************************************************
      * TARGET DB2 TABLE HOST STRUCTURES (UPDATED FOR MAXIMUM LENGTHS)
      ******************************************************************
       01  H-EMPLOYEE-RECORD.
           
           05 H-ID.
              49 H-ID-LEN      PIC S9(4)      COMP.
              49 H-ID-TEXT     PIC X(100).
           
           05 H-EMP-NAME.
              49 H-NAME-LEN    PIC S9(4)      COMP.
              49 H-NAME-TEXT   PIC X(200).
              
           05 H-WAGE.
              49 H-WAGE-LEN    PIC S9(4)      COMP.
              49 H-WAGE-TEXT   PIC X(100).
           
           05 H-STREET.
              49 H-STR-LEN     PIC S9(4)      COMP.
              49 H-STR-TEXT    PIC X(100).
              
           05 H-TELEPHONE.
              49 H-TEL-LEN     PIC S9(4)      COMP.
              49 H-TEL-TEXT    PIC X(100).

      ******************************************************************
      * DB2 NULL INDICATORS (ENABLED AS REQUESTED)
      ******************************************************************
       01  H-NULL-INDICATORS.
           05 NI-STREET        PIC S9(4)      COMP.
              88 STR-IS-NULL                  VALUE -1.
              88 STR-NOT-NULL                 VALUE 0.
           05 NI-TELEPHONE     PIC S9(4)      COMP.
              88 TEL-IS-NULL                  VALUE -1.
              88 TEL-NOT-NULL                 VALUE 0.
