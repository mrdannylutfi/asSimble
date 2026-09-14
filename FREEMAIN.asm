MYPROG   CSECT 
MYPROG   AMODE 31
MYPROG   RMODE ANY
         PRINT NOGEN
* =====================================================================
* STANDARD ENTRY LINKAGE & GETMAIN (THREAD-SAFE)
* =====================================================================
         BAKR  R14,0               Save registers on OS Linkage Stack
         BALR  R12,0               Establish program base register
         USING *,R12               Inform assembler R12 is code base
*
         LR    R10,R1              Preserve incoming Token Pointer in R10
         USING ENVTOKEN,R10        Map the input token structure
*
* Allocate dynamic thread workspace using traditional GETMAIN
         GETMAIN RU,LV=WAKSIZE     Request Unconditional Reentrant storage
         LR    R11,R1              R11 = Address of allocated storage
         USING WORKAREA,R11        Map WorkArea DSECT to R11
*
* =====================================================================
* BUSINESS LOGIC WITH REGISTER TOKEN PROCESSING & BC BRANCHING
* =====================================================================
         L     R3,TOKARRPTR        Extract Array Pointer from Token
         L     R4,TOKELEMNUM       Extract Element Count from Token
         L     R7,TOKTBLPTR        Extract Thread-Specific Table from Token
*
         XC    TOTAL,TOTAL         Clear thread-isolated total variable
*
LOOPHEAD EQU   *
         C     R4,=F'0'            Compare loop counter to zero
         BC    8,LOOPEND           BC Mask 8 (BE) -> Exit if loop done
*
         L     R5,0(,R3)           Load current element from array
*
* --- Begin Multi-Choice Table Resolution ---
         LR    R6,R7               Copy base table pointer for iterating
         L     R8,0(,R6)           First entry in our table is row count
         LA    R6,4(,R6)           Advance pointer past count to first row
*
CHKTBL   EQU   *
         C     R5,0(,R6)           Compare element against table criteria
         BC    8,FOUNDIT           BC Mask 8 (BE) -> Winner found!
         LA    R6,8(,R6)           Advance to next table row (size = 8)
         BCT   R8,CHKTBL           Decrement R8, branch if > 0 using BCT
*
* --- Default Condition (No Table Matches) ---
         BC    15,NEXTITER         BC Mask 15 (B) -> Skip to next item
*
FOUNDIT  EQU   *
         L     R9,4(,R6)           Load modifier value from table row
         A     R5,TOTAL            Add current running total
         AR    R5,R9               Apply winner modification to element
         ST    R5,TOTAL            Store back to thread-isolated memory
*
NEXTITER EQU   *
         LA    R3,4(,R3)           Advance array pointer 4 bytes
         S     R4,=F'1'            Decrement loop counter manually
         BC    15,LOOPHEAD         BC Mask 15 (B) -> Repeat loop
*
LOOPEND  EQU   *
         L     R15,TOTAL           Put final thread result in Return Reg 15
*
* =====================================================================
* STANDARD EXIT LINKAGE & FREEMAIN (CLEANUP & RETURN)
* =====================================================================
* Release dynamic thread workspace using traditional FREEMAIN
         FREEMAIN RU,LV=WAKSIZE,A=(11) Free thread-isolated memory
*
         PR                        Program Return via Linkage Stack
*
         LTORG                     Force Literal Pool inside code bounds
*
* =====================================================================
* INPUT TOKEN MAPPING DSECT (INPUT PARAMETERS)
* =====================================================================
ENVTOKEN DSECT                     Maps incoming R1/R10 Context Token
TOKARRPTR DS    A                   Pointer to the data array
TOKELEMNUM DS   F                   Number of elements in the array
TOKTBLPTR DS    A                   Pointer to the thread's choice table
*
* =====================================================================
* DYNAMIC WORKAREA DSECT (THREAD-SAFE STATE)
* =====================================================================
WORKAREA DSECT                     Maps structure allocated via GETMAIN
TOTAL    DS    F                   Dynamic thread-isolated running total
WAKSIZE  EQU   *-WORKAREA          Calculated size of dynamic work area
*
         END   MYPROG
