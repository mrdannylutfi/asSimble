MATCHED  EQU   *
* Extract the 4-byte payload from the table row
         L     R15,1(,R5)        Load the payload value into temporary R15
* 
* Extract output anchor from parameter list block
         L     R1,0(,R1)         Reload input parameter list anchor (if modified)
* Note: Assume your parameter list structure maps a second word for the output area:
* e.g., TOKOUTPTR DS A           Address where caller wants the payload stored
         L     R14,TOKOUTPTR     Get the caller's target buffer address
         ST    R15,0(,R14)       Store extracted payload directly into caller memory
* 
         XC    RETCODE,RETCODE   Set Return Code to 0 (Success)
         J     EXIT_PROC
