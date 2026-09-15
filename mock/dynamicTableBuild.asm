* =====================================================================
* ROUTINE: BLDTBL - DYNAMICALLY BUILD ALIGNED VECTOR-SAFE ROWS
* =====================================================================
* Inputs:  R2 = Address of Raw Null-Terminated ASCII String
*          R3 = 4-Byte Payload Value
*          R4 = Address of Current Heap Storage Pointer (Free Memory Space)
*          R11= Current Row Pointer (Updated by routine to chain entries)
* Outputs: R4 = Advanced to next free memory block slot
* =====================================================================
BLDTBL   EQU   *
         BAKR  R14,0               Save driver context on Linkage Stack
*
* 1. Align the starting address of the new row on an 8-byte boundary
         LA    R4,7(,R4)           Add alignment headroom
         NILF  R4,X'FFFFFFF8'      Clear lowest 3 bits to align to 0 or 8
*
* 2. Initialize current row pointers
         USING TBLROW,R4           Map DSECT to our active heap allocation pointer
         XC    TBLROW(8),TBLROW    Clear control pointers (ROWNEXT = 0)
         MVI   ROWFLAGS,X'00'      Reset control flags
*
* 3. Chain the rows together if this isn't the first entry
         CFI   R11,0               Is this the first row?
         BE    FIRSTROW            If yes, skip backward linking
         USING TBLROW,R11          Map previous row layout to R11
         ST    R4,ROWNEXT          Point previous row's chain pointer to new row
         USING TBLROW,R4           Restore mapping back to new row address
*
FIRSTROW EQU   *
         LR    R11,R4              Update tracker: this row is now the previous row
*
* 4. Copy the raw ASCII string text into the row layout
         LA    R5,ROWTEXT          Target destination for the text copy
*
COPYLOOP EQU   *
         LLC   R6,0(,R2)           Load byte from source string
         STC   R6,0(,R5)           Store byte into row string
         LA    R2,1(,R2)           Advance source string pointer
         LA    R5,1(,R5)           Advance row target pointer
         CIJNE R6,0,COPYLOOP       Continue copying until \0 is written
*
* R5 now points exactly 1 byte past the null terminator string boundary.
* 5. Embed the 4-byte payload right at this exact relative boundary
         ST    R3,0(,R5)           Store the 4-byte payload
*
* 6. Advance the memory allocator pointer past the payload entry
         LA    R4,4(,R5)           Point past payload to next available byte
*
         PR    ,                   Return cleanly to the Driver program
