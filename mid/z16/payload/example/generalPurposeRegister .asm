MATCHED  EQU   *
* Extract the 4-byte payload located 1 byte past the null terminator
         L     R0,1(,R5)         Place payload value directly into R0
         XC    RETCODE,RETCODE   Set Return Code to 0 (Success)
         J     EXIT_PROC         Proceed to storage release and PR
