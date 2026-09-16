       2000-PROCESS-AND-INSERT.
      *    1. MAP ID
           MOVE IN-ID TO H-ID-TEXT.
           COMPUTE H-ID-LEN = FUNCTION LENGTH(IN-ID).

      *    2. MAP EMPLOYEE NAME
           MOVE IN-NAME TO H-NAME-TEXT.
           INSPECT FUNCTION REVERSE(IN-NAME) 
               TALLYING H-NAME-LEN FOR LEADING SPACES.
           COMPUTE H-NAME-LEN = 200 - H-NAME-LEN.

      *    3. MAP WAGE
           MOVE IN-WAGE TO H-WAGE-TEXT.
           COMPUTE H-WAGE-LEN = FUNCTION LENGTH(IN-WAGE).

      *    4. MAP STREET WITH ACTIVE NULL HANDLING
           IF IN-STREET = SPACES
               SET STR-IS-NULL TO TRUE
               MOVE ZERO TO H-STR-LEN
               MOVE SPACES TO H-STR-TEXT
           ELSE
               SET STR-NOT-NULL TO TRUE
               MOVE IN-STREET TO H-STR-TEXT
               INSPECT FUNCTION REVERSE(IN-STREET) 
                   TALLYING H-STR-LEN FOR LEADING SPACES
               COMPUTE H-STR-LEN = 100 - H-STR-LEN
           END-IF.

      *    5. MAP TELEPHONE WITH ACTIVE NULL HANDLING
           IF IN-TELEPHONE = SPACES OR IN-TELEPHONE = ZERO
               SET TEL-IS-NULL TO TRUE
               MOVE ZERO TO H-TEL-LEN
               MOVE SPACES TO H-TEL-TEXT
           ELSE
               SET TEL-NOT-NULL TO TRUE
               MOVE IN-TELEPHONE TO H-TEL-TEXT
               INSPECT FUNCTION REVERSE(IN-TELEPHONE) 
                   TALLYING H-TEL-LEN FOR LEADING SPACES
               COMPUTE H-TEL-LEN = 100 - H-TEL-LEN
           END-IF.

      *    6. EXECUTE EMBEDDED SQL INSERT STATEMENT
           EXEC SQL
               INSERT INTO YOUR_SCHEMA.EMPLOYEE_TABLE
               ( ID, 
                 EMPLOYEE_NAME, 
                 WAGE, 
                 STREET, 
                 TELEPHONE )
               VALUES
               ( :H-ID,
                 :H-EMP-NAME,
                 :H-WAGE,
                 :H-STREET    :NI-STREET,
                 :H-TELEPHONE :NI-TELEPHONE )
           END-EXEC.

      *    7. ERROR CHECKING
           IF SQLCODE NOT = 0
               DISPLAY 'INSERT FAILED FOR ID: ' H-ID-TEXT ' CODE: ' SQLCODE
               PERFORM 9999-ABEND-PROGRAM
           END-IF.
