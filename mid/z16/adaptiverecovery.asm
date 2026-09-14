* =====================================================================
* Z16 VECTOR-ACCELERATED CHARACTER STRING MATCHING LOOP
* =====================================================================
* R3 = Pointer to input string to match
* R4 = Input string length (1-based for Vector operations)
* R7 = Current Table Row Pointer (Address of TBLROW)
* R8 = Table Row Counter
* ---------------------------------------------------------------------
* Pre-load the search argument into Vector Register 1 (V1)
* If string is <= 16 bytes, we can use Vector Load to Limit or Vector Load Element
         VLL   V1,R4,0(R3)       Load search string into V1 up to length in R4
*
CHKTBL   EQU   *
         CIJNH R8,0,ERR_NOTFND   Exit if row counter exhausted
*
         USING TBLROW,R7         Map current row layout
         LH    R5,ROWLEN         Get current row text length
         CRJNE R5,R4,NEXTROW     Lengths don't match? Skip immediately.
*
* Vector String Comparison (Up to 16 bytes at once)
         VLL   V2,R5,ROWTEXT     Load row text into V2 up to length in R5
         VFEEB V3,V1,V2,Z        Find first unequal byte index; set CC
*                                  'Z' flag checks for zero/null if string-terminated
*                                  Sets CC=0 if a match is found across the span
         BC    4,MATCHED         Mask 4 (CC=0): All elements equal -> MATCH!
*
NEXTROW  EQU   *
         L     R7,ROWNEXT        Follow pointer directly to next row
         AHI   R8,-1             Decrement loop counter
         J     CHKTBL            Jump relative back to check
*
MATCHED  EQU   *
*        ... Handle successful match found at address in R7 ...
