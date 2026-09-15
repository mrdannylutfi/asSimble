* =====================================================================
* VARIABLE-LENGTH MULTI-CHOICE RESOLUTION ROUTINE (z/Architecture 64-Bit)
* =====================================================================
* R5 = Pointer to the input string to evaluate
* R7 = Current position in the variable-length table (64-bit pointer)
* R8 = Table loop counter (number of entries left)
* ---------------------------------------------------------------------
         LG    R7,TOKTBLPTR        Extract 64-bit Table Pointer from Token
         LLGF  R8,0(,R7)           Load 32-bit row count into 64-bit GPR, zero upper
         LA    R7,4(,R7)           Advance past count word to first row header
*
CHKTBL   EQU   *
         CIJ   R8,0,8,DEFAULT      Compare Immediate and Jump if 0 (Equal) to Default
*
* Map the layout dynamically using 64-bit registers
         LLGH  R2,0(,R7)           R2 = Total Row Length (Zero-extended to 64-bit)
         LLGH  R9,2(,R7)           R9 = Comparison field length (Zero-extended)
*
* Execute variable-length comparison using EXecute Relative Long
         BCTR  R9,0                Decrement length by 1 for machine code footprint
         EXRL  R9,COMPVAR          Execute CLC using relative long (no base reg needed)
         BRC   8,FOUNDIT           Branch Relative on Condition (BE) -> Winner found!
*
* --- Not a match: Step over variable row length ---
         AGR   R7,R2               64-bit binary add: Advance pointer to next row
         AHI   R8,-1               Add Halfword Immediate: Decrement loop counter
         BRC   15,CHKTBL           Branch Relative Condition (Always) -> Loop back
*
FOUNDIT  EQU   *
* Calculate start of the modifier value (Offset 4 + Comparison Length)
         LA    R6,4(,R7)           R6 = Pointer past row header (Offset 4)
         AGR   R6,R9               R6 = Slide past variable match string (using 64-bit length)
         AHI   R6,1                Readjust for the BCTR decrement performed earlier
         LG    R10,0(,R6)          R10 = Load the 64-bit target payload!
*
* ... continue to accumulator logic ...
*
* ---------------------------------------------------------------------
* REMOTE EXECUTED INSTRUCTION (Placed in a non-executable data area)
* ---------------------------------------------------------------------
COMPVAR  CLC   0(0,R5),4(R7)       Compares string at (R5) vs Table at (R7+4)
