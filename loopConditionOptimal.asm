MYPROG   CSECT
MYPROG   AMODE 31
MYPROG   RMODE ANY
         PRINT NOGEN
* =====================================================================
* STANDARD ENTRY LINKAGE (REENTRANT)
* =====================================================================
         BAKR  R14,0               Save registers and return info on linkage stack
         BASR  R12,0               Establish program base register
         USING *,R12
*
         L     R0,WAKSIZE          Get dynamic workspace size
         STORAGE OBTAIN,LENGTH=(0),LOC=31 Allocate dynamic memory for thread
         LR    R11,R1)             R11 = Pointer to our dynamic storage
         USING WORKAREA,R11        Map WorkArea DSECT to R11
*
* =====================================================================
* BUSINESS LOGIC (REENTRANT FOR-LOOP)
* =====================================================================
         L     R3,0(,R1)           R3 = Address of input array passed via R1
         L     R4,4(,R1)           R4 = Element count passed via R1
*
         SR    R5,R5               Clear R5 (Our thread-safe accumulator)
         ST    R5,TOTAL            Initialize dynamic storage variable to 0
*
SUMLOOP  EQU   *
         LTR   R4,R4               Check if array count is 0 or exhausted
         JZ    LOOPEND             If zero, exit loop
*
         L     R6,0(,R3)           Load array element into R6
         A     R5,TOTAL            Add current total from dynamic storage
         AR    R5,R6               Add current element
         ST    R5,TOTAL            Save back to thread-isolated dynamic storage
*
         LA    R3,4(,R3)           Point to next array element (4 bytes forward)
         BCTR  R4,0                Decrement loop counter by 1
         B     SUMLOOP             Repeat
*
LOOPEND  EQU   *
         L     R15,TOTAL           Move final result to Return Register 15
*
* =====================================================================
* STANDARD EXIT LINKAGE (CLEANUP & RETURN)
* =====================================================================
         L     R0,WAKSIZE          Load storage size to release
         STORAGE RELEASE,LENGTH=(0),ADDR=(11) Free thread isolated memory
         PR                        Program Return (Restores regs via Linkage Stack)
*
* =====================================================================
* CONSTANTS (READ-ONLY)
* =====================================================================
WAKSIZE  DC    F'L''WORKAREA'       Size of dynamic work area
*
* =====================================================================
* DYNAMIC WORK RECTANGLE (MAPPED STORAGE DEFINITION)
* =====================================================================
WORKAREA DSECT                     This does not allocate memory here!
TOTAL    DS    F                   Thread-safe local variable
         END   MYPROG
