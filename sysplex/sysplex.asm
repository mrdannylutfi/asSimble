* =====================================================================
* DUAL-PATH ARCHITECTURE LOGIC WITH HARDWARE SPECPLEX TEST
* =====================================================================
* Establish working space inside our allocated WORKAREA DSECT
WORKAREA DSECT
TOTAL    DS    F
RETCODE  DS    F
FACLIST  DS    4D                4 doublewords (32 bytes) for STFLE output
WAKSIZE  EQU   *-WORKAREA
*
MYPROG   CSECT
* ... standard linkage stack entry / allocation omitted for space ...
*
* 1. Check CPU Facility bits for Vector Support
         MVI   FACLIST,X'03'     Set count minus 1 (request 4 doublewords)
         STFLE FACLIST           Store facility list into our workarea
*
* Test Bit 129 (Byte 16, Bit 1) for basic Vector Facility availability
         TM    FACLIST+16,X'40'  Is bit 129 on? (Vector Facility active)
         BNO   LEGACY_PATH       No vector unit? Safely branch to legacy pipeline!
*
* =====================================================================
* OPTION 1: HIGH-PERFORMANCE Z16 VECTOR ENGINE PATH
* =====================================================================
VECTOR_PATH EQU *
* ... [Insert the complete z16 vector striding code block here] ...
* When match is found:
         VLGVB R1,V3,7           Extract index byte from vector comparison
         AR    R5,R1             R5 = Points to '\0' in row text
         LA    R5,1(,R5)         R5 = Points to start of variable payload
         J     EXT_PAYLOAD       Jump to common payload handling
*
* =====================================================================
* OPTION 2: SCALAR BACKWARDS-COMPATIBILITY FALLBACK PATH (Pre-z16)
* =====================================================================
LEGACY_PATH EQU *
         L     R7,TOKTBLPTR      R7 = Extract Thread-Specific Table Base
         L     R8,0(,R7)         R8 = Row count
         LA    R7,4(,R7)         R7 = Advance to first row header
*
LEG_LOOP EQU   *
         CIJNH R8,0,ERR_NOTFND   Rows exhausted? Exit.
         USING TBLROW,R7
*
* Since strings are variable C-strings, calculate the length of input needle
         L     R9,TOKARRPTR      R9 = Start of Input String
         LA    R1,0              R1 = Length Counter
LEG_LEN  EQU   *
         CLI   0(R9),X'00'       Hit null terminator?
         BE    LEG_LEND          Yes, length found.
         LA    R9,1(,R9)
         LA    R1,1(,R1)
         CFI   R1,MAX_LEN        Enforce overrun guard
         BH    ERR_OVERRUN
         J     LEG_LEN
*
LEG_LEND EQU   *
* R1 now contains the exact length of the search string (excluding \0)
* Check if Row text matches byte-for-byte using EXRL/CLC
         L     R9,TOKARRPTR      Reset input needle pointer
         LA    R5,ROWTEXT        R5 = Start of row text
*
* Perform dynamic execution length calculation (EXRL length must be length-1)
         AHI   R1,-1             Subtract 1 for EX execution framework
         JM    LEG_NEXT          If original length was 0, handle empty text match bounds
         EXRL  R1,EX_CLC         Execute dynamic CLC instruction
         BNE   LEG_NEXT          No match? Skip row.
*
* Verify that the row text ALSO ends at this exact same byte index
         LA    R2,1(R1,R5)       Advance past compared bytes to termination index
         CLI   0(R2),X'00'       Is it a true null boundary?
         BE    LEG_MATCH         Yes! Lengths match and text matches -> True Success
*
LEG_NEXT EQU   *
         L     R7,ROWNEXT        Follow forward pointer block chain
         AHI   R8,-1             Decrement counter
         J     LEG_LOOP
*
* Target instruction for the EXRL instruction frame
EX_CLC   CLC   0(0,R9),0(R5)     Compares input criteria against active row text
*
LEG_MATCH EQU  *
         LA    R5,1(R1,R5)       Advance past text characters
         LA    R5,1(,R5)         Advance 1 extra byte past the \0 terminator
*        R5 now safely points directly to the start of the Variable Payload area
*
* =====================================================================
* COMMON BUSINESS LOGIC: VARIABLE PAYLOAD DATA EXTRACTION
* =====================================================================
EXT_PAYLOAD EQU *
         LH    R2,ROWPLEN        Extract variable payload footprint size from header
         L     R14,TOKOUTPTR     Get destination caller block pointer 
*
* Copy variable-length payload into caller space
         AHI   R2,-1             Adjust length modifier for MVCL / EXRL copy
         JM    EXT_DONE          If size is 0, nothing to move
         EXRL  R2,EX_MVC         Execute the payload transfer
*
EXT_DONE EQU   *
         XC    RETCODE,RETCODE   Set RC=0
         J     EXIT_PROC
*
EX_MVC   MVC   0(0,R14),0(R5)    Moves payload data safely to target buffer address
