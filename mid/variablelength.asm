* =====================================================================
* VARIABLE-LENGTH MULTI-CHOICE RESOLUTION ROUTINE
* =====================================================================
* R5 = Element to evaluate
* R7 = Current position in the variable-length table
* R8 = Table loop counter (number of entries left)
* ---------------------------------------------------------------------
         L     R7,TOKTBLPTR        Extract Thread Table from Token
         L     R8,0(,R7)           First fullword is row count
         LA    R7,4(,R7)           Advance past count to first row header
*
CHKTBL   EQU   *
         C     R8,=F'0'            Check if table entries exhausted
         BC    8,DEFAULT           BC Mask 8 (BE) -> Go to default logic
*
* Map the layout dynamically using registers
         LH    R2,0(,R7)           R2 = Total Row Length (used to skip later)
         LH    R9,2(,R7)           R9 = Comparison field length
*
* Execute comparison (assuming fullword integers here for simple proof)
         C     R5,4(,R7)           Compare our input against row criteria
         BC    8,FOUNDIT           BC Mask 8 (BE) -> Winner found!
*
* --- Not a match: Step over variable row length ---
         AR    R7,R2               Add row length to current pointer!
         S     R8,=F'1'            Decrement remaining row count
         BC    15,CHKTBL           BC Mask 15 (B) -> Check next entry
*
FOUNDIT  EQU   *
* Calculate start of the modifier value (Offset + 4 + Comparison Length)
         LA    R6,4(,R7)           R6 = Pointer past row header
         AR    R6,R9               R6 = Slide past variable match string
         L     R10,0(,R6)          R10 = Load the variable target payload!
*
* ... continue to accumulator logic ...
