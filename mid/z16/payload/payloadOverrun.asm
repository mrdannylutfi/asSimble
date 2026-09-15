* =====================================================================
* Z16 TEXT-STRIDING MATCH ENGINE WITH TRACKING & PAYLOAD EXTRACT
* =====================================================================
* R3 = Pointer to input string (from parameter token)
* R7 = Current Table Row Pointer (Address of TBLROW)
* R8 = Table Row Counter
* ---------------------------------------------------------------------
MAX_LEN  EQU   4096                Maximum safe length for C-String (4KB)
*
CHKTBL   EQU   *
         CIJNH R8,0,ERR_NOTFND     Exit if table rows exhausted
         
         USING TBLROW,R7           Map row structure
         L     R9,TOKARRPTR        R9 = Reset pointer to start of Input String
         LA    R5,ROWTEXT          R5 = Pointer to start of current Row Text
         LA    R6,0                R6 = Accumulator for length tracking
*
STRIDELP EQU   *
* Enforce maximum safe string length safety tracking
         CFI   R6,MAX_LEN          Has our stride tracking exceeded safe limits?
         BH    ERR_OVERRUN         Branch to error handler if length > 4096
*
         VL    V1,0(,R9)           Load 16 bytes of Input String into V1
         VL    V2,0(,R5)           Load 16 bytes of Row String into V2
*
* Compare V1 and V2 byte-by-byte. 
* 'Z' searches for a null (\0) terminator in both registers.
* 'S' updates the Condition Code (CC) to describe the exact result.
         VFEEBS V3,V1,V2,Z
*
* Condition Code Analysis:
* CC=3 : All elements equal, no zero elements found (Stride matched, continue)
* CC=2 : A zero element was found at an index lower than/equal to an unequal element
* CC=0 or 1 : A mismatch occurred before hitting a string end
*
         BC    2,STRIDE_CONT       Mask 2 (CC=3): 16-byte match, no \0. Next stride!
         BC    4,CHECK_END         Mask 4 (CC=2): Zero/Null found! Verify final match.
*
NEXTROW  EQU   *
         L     R7,ROWNEXT          Follow pointer to next row DSECT
         AHI   R8,-1               Decrement row counter
         J     CHKTBL              Jump back to top of table evaluation
*
STRIDE_CONT EQU *
         LA    R9,16(,R9)          Advance Input String address by 16 bytes
         LA    R5,16(,R5)          Advance Row String address by 16 bytes
         AHI   R6,16               Track processed string footprint
         J     STRIDELP            Process next 16-byte stride
*
CHECK_END EQU  *
* Found a null terminator. Verify that BOTH strings ended identically.
         VLGVB R1,V3,7             Extract the match index byte into GPR1
         AR    R9,R1               Point to final character/null in Input
         AR    R5,R1               Point to final character/null in Row
         LLC   R2,0(,R9)           Load byte from Input String
         LLC   R4,0(,R5)           Load byte from Row String
         CRJNE R2,R4,NEXTROW       If mismatch (one ended early), fail row.
*
MATCHED  EQU   *
* =====================================================================
* BUSINESS LOGIC: EXTRAC PAYLOAD FROM MATCHED ROW
* =====================================================================
* Assuming payload value is stored exactly 1 byte past the null terminator:
         L     R15,1(,R5)          Extract the 4-byte payload into R15
         ST    R15,TOTAL           Store payload into thread-isolated total workspace
         XC    RETCODE,RETCODE     Explicitly set Return Code to 0 (Success)
         J     EXIT_PROC           Jump to program teardown
*
* =====================================================================
* ERROR HANDLING PATHS
* =====================================================================
ERR_OVERRUN EQU *
         LA    R15,8               RC=8: String buffer memory overrun violation
         ST    R15,RETCODE         Set structural error return code
         J     EXIT_PROC           Terminate processing safely
*
ERR_NOTFND EQU *
         LA    R15,4               RC=4: Table scanned completely, no match found
         ST    R15,RETCODE
*
EXIT_PROC EQU  *
* Code continues into STORAGE RELEASE and PR return linkage stack logic...
