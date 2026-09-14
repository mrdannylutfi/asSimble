* =====================================================================
* MULTI-CHOICE RESOLUTION (TABLE-DRIVEN EVALUATION)
* =====================================================================
EVALCODE EQU   *
         L     R2,INPUTVAL         R2 = Condition value to check
         LA    R6,CONDTBL          R6 = Pointer to lookup table
         LA    R7,TBLNUM           R7 = Number of table entries
*
CHKTBL   EQU   *
         C     R2,0(,R6)           Does input match this table entry?
         BE    FOUNDIT             Yes! Jump to the resolution logic
         LA    R6,8(,R6)           No, advance to next entry (size = 8)
         BCT   R7,CHKTBL           Loop until table exhausted
*
         B     DEFAULT             No match found ("Else" condition)
*
FOUNDIT  EQU   *
         L     R8,4(,R6)           R8 = Address of the winning routine
         BR    R8                  Branch to the winner
*
* ---------------------------------------------------------------------
* STATIC LOOKUP TABLE (ReadOnly / Thread-Safe Static Storage)
* ---------------------------------------------------------------------
CONDTBL  DS    0F
         DC    F'10',A(ROUTINEA)   If 10, go to Routine A
         DC    F'20',A(ROUTINEB)   If 20, go to Routine B
         DC    F'30',A(ROUTINEC)   If 30, go to Routine C
TBLNUM   EQU   (*-CONDTBL)/8       Calculate total table entries dynamically
