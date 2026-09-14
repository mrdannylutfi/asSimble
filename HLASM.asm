MYPROG   CSECT 
MYPROG   AMODE 31
MYPROG   RMODE ANY
         PRINT NOGEN
* =====================================================================
* STANDARD ENTRY LINKAGE (REENTRANT)
* =====================================================================
         BAKR  R14,0               Save regs on OS Linkage Stack
         BALR  R12,0               Establish program base register
         USING *,R12               Inform assembler R12 is code base
*
         L     R0,WAKSIZE          Get dynamic workspace size
         STORAGE OBTAIN,LENGTH=(0),LOC=31 Allocate dynamic memory for thread
         LR    R11,R1              R11 = Pointer to our dynamic storage
         USING WORKAREA,R11        Map WorkArea DSECT to R11
*
* =====================================================================
* FOR-LOOP & MULTI-CHOICE CONDITION RESOLUTION
* =====================================================================
* Register Setup:
* R3 = Array Pointer, R4 = Loop Counter, R5 = Accumulator
* R7 = Table Base, R8 = Table Counter
* ---------------------------------------------------------------------
         L     R3,0(,1)            R1 passed pointer to Array Pointer
         L     R4,4(,1)            R1 passed pointer to Element Count
         XC    TOTAL,TOTAL         Clear thread-isolated total variable
*
LOOPHEAD EQU   *
         C     R4,=F'0'            Compare loop counter to zero
         BC    8,LOOPEND           BC Mask 8 (BE) -> Exit if loop done
*
         L     R5,0(,R3)           Load current element from array
*
* --- Begin Multi-Choice "Winner" Table Resolution ---
         LA    R7,CONDTBL          R7 = Point to static condition table
         LA    R8,TBLNUM           R8 = Number of table entries
*
CHKTBL   EQU   *
         C     R5,0(,R7)           Compare element against table criteria
         BC    8,FOUNDIT           BC Mask 8 (BE) -> We have a winner!
         LA    R7,8(,R7)           Advance to next table row (size = 8)
         BCT   R8,CHKTBL           Decrement R8, branch if > 0 using BCT
*
* --- Default Condition (No Table Matches) ---
         A     R5,=F'1'            Add default penalty if no match
         BC    15,ACCUM            BC Mask 15 (B) -> Unconditional jump
*
FOUNDIT  EQU   *
         L     R9,4(,R7)           Load modifier/weight value from table row
         AR    R5,R9               Apply winner modification to element
*
ACCUM    EQU   *
         A     R5,TOTAL            Add current running total
         ST    R5,TOTAL            Store back to thread-safe memory
*
* --- Loop Increment and Repeat ---
         LA    R3,4(,R3)           Advance array pointer 4 bytes
         S     R4,=F'1'            Decrement loop counter manually
         BC    15,LOOPHEAD         BC Mask 15 (B) -> Repeat loop
*
LOOPEND  EQU   *
         L     R15,TOTAL           Put final thread result in Return Reg 15
*
* =====================================================================
* STANDARD EXIT LINKAGE (CLEANUP & RETURN)
* =====================================================================
         L     R0,WAKSIZE          Load storage size to release
         STORAGE RELEASE,LENGTH=(0),ADDR=(11) Free thread-isolated memory
         PR                        Program Return via Linkage Stack
*
         LTORG                     Force Literal Pool inside code bounds
*
* =====================================================================
* READ-ONLY STATIC LOOKUP DATA
* =====================================================================
WAKSIZE  DC    F'L''WORKAREA'       Calculated size of dynamic work area
*
CONDTBL  DS    0F                  Condition Target Table
         DC    F'100',F'50'        If value is 100, add a bonus of 50
         DC    F'200',F'100'       If value is 200, add a bonus of 100
         DC    F'300',F'150'       If value is 300, add a bonus of 150
TBLNUM   EQU   (*-CONDTBL)/8       Dynamically calculated table entry count
*
* =====================================================================
* DYNAMIC WORKAREA (THREAD-SAFE STATE)
* =====================================================================
WORKAREA DSECT                     Maps structure, consumes no static memory
TOTAL    DS    F                   Dynamic thread-isolated running total
         END   MYPROG
