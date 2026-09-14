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
* Initialize local states
         XC    TOTAL,TOTAL         Clear thread-isolated total variable
         XC    RETCODE,RETCODE     Set default Return Code to 0 (Success)
*
* =====================================================================
* BUSINESS LOGIC: VARIABLE-LENGTH CHARACTER STRING MATCHING (CLC)
* =====================================================================
* R3 = Pointer to input string to match, R4 = Input string length (-1)
* R7 = Table Base, R8 = Table Row Counter
* ---------------------------------------------------------------------
         L     R3,TOKARRPTR        Pointer to the text string we want to evaluate
         LH    R4,TOKINPLEN        Get input string length (0-indexed for EX)
         L     R7,TOKTBLPTR        Extract Thread-Specific Table from Token
         L     R8,0(,R7)           First fullword is row count
         LA    R7,4(,R7)           Advance past count to first row header
*
CHKTBL   EQU   *
         C     R8,=F'0'            Check if table entries exhausted
         BC    8,ERR_NOTFND        BC Mask 8 (BE) -> Error: Counter ran out!
*
* Fetch row metrics for dynamic stepping
         LH    R2,0(,R7)           R2 = Total Row Length
         LTR   R2,R2               Validate length is greater than 0
         BC    2,LEN_OK            BC Mask 2 (BP) -> Positive length is OK
         BC    15,ERR_STRUCT       BC Mask 15 -> Error: Table layout corrupt!
*
LEN_OK   EQU   *
         LH    R9,2(,R7)           R9 = Target string comparison length (-1)
*
* Dynamic length safety check: Only execute CLC if lengths match
         CR    R4,R9               Is our input length equal to table item length?
         BC    7,NEXTITER          BC Mask 7 (BNE) -> Mismatch, skip to next row
*
* Execute the variable-length CLC via the EX instruction
         LA    R6,4(,R7)           R6 points to character data in table row
         EX    R4,EX_CLC_INSTR     Execute: CLC 0(0,R3),0(R6)
         BC    8,FOUNDIT           BC Mask 8 (BE) -> Match found!
*
NEXTITER EQU   *
         AR    R7,R2               Advance pointer by total variable row size
         S     R8,=F'1'            Decrement remaining row count
         BC    15,CHKTBL           BC Mask 15 (B) -> Loop again
*
FOUNDIT  EQU   *
* Calculate payload address: Offset + 4 + (Comparison Length + 1)
         LA    R6,4(,R7)           Point to start of string text
         AR    R6,R9               Slide past length bytes
         LA    R6,1(,R6)           Account for the 0-indexed offset shift
         L     R15,0(,R6)          Load fullword modifier payload!
         ST    R15,TOTAL           Store result into thread-safe workspace
         BC    15,CLEANUP          BC Mask 15 (B) -> Proceed to exit
*
* =====================================================================
* ERROR & RECOVERY CODE PATHWAY
* =====================================================================
ERR_NOTFND EQU  *
         MVC   RETCODE,=F'8'       RC=8: Table processed but string not found
         BC    15,CLEANUP
*
ERR_STRUCT EQU  *
         MVC   RETCODE,=F'12'      RC=12: Structural failure (infinite loop guard)
         BC    15,CLEANUP
*
* =====================================================================
* STANDARD EXIT LINKAGE & FREEMAIN (CLEANUP & RETURN)
* =====================================================================
CLEANUP  EQU   *
         L     R15,RETCODE         Load final structural return code
         C     R15,=F'0'           Check if successful
         BC    7,EXIT_NOW          If error, bypass updating total
         L     R15,TOTAL           On success, return calculated payload
*
EXIT_NOW EQU   *
         LR    R2,R15              Temporarily save return value
         FREEMAIN RU,LV=WAKSIZE,A=(11) Free thread-isolated memory
         LR    R15,R2              Restore return value into R15 for caller
         PR                        Program Return via Linkage Stack
*
* =====================================================================
* REMOTE EXECUTED INSTRUCTIONS (TARGETS FOR EX)
* =====================================================================
EX_CLC_INSTR CLC 0(0,R3),0(R6)     Executed instruction template
         LTORG                     Force Literal Pool inside code bounds
*
* =====================================================================
* INPUT TOKEN MAPPING DSECT (INPUT PARAMETERS)
* =====================================================================
ENVTOKEN DSECT                     Maps incoming R1/R10 Context Token
TOKARRPTR  DS   A                  Pointer to the dynamic match string
TOKINPLEN  DS   H                  Length of input match string (minus 1)
           DS   XL2                Reserved padding for alignment
TOKTBLPTR  DS   A                  Pointer to the thread's choice table
*
* =====================================================================
* DYNAMIC WORKAREA DSECT (THREAD-SAFE STATE)
* =====================================================================
WORKAREA DSECT                     Maps structure allocated via GETMAIN
TOTAL    DS    F                   Dynamic thread-isolated result storage
RETCODE  DS    F                   Thread execution safety status code
WAKSIZE  EQU   *-WORKAREA          Calculated size of dynamic work area
*
         END   MYPROG
