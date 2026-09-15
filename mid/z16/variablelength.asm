CHKTBL   EQU   *
         C     R8,=F'0'            Check if table entries exhausted
         BC    8,DEFAULT           BC Mask 8 (BE) -> Go to default logic
*
* Map the layout dynamically using registers
         LH    R2,0(,R7)           R2 = Total Row Length (including header)
         LH    R9,2(,R7)           R9 = Comparison field length
*
* Execute variable-length comparison using EX and CLC
         BCTR  R9,0                Decrement length by 1 for machine code EX
         EX    R9,COMPVAR          Execute the CLC with dynamic length
         BC    8,FOUNDIT           BC Mask 8 (BE) -> Winner found!
*
* --- Not a match: Step over variable row length ---
         AR    R7,R2               Advance pointer by total row length
         BCTR  R8,0                Decrement remaining row count (or use S)
         BC    15,CHKTBL           Loop back
*
* --- Helper Instruction Table (Target of EX) ---
COMPVAR  CLC   0(0,R5),4(R7)       Compares R5 target string vs table offset 4
* Note: This assumes R5 is a pointer to the input string, not the data itself.
