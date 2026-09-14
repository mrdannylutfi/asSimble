* =====================================================================
* Z16 TEXT-STRIDING MATCH ENGINE (NULL-TERMINATED ASCII)
* =====================================================================
* R3 = Pointer to current stride of Input String (Search Criteria)
* R7 = Current Table Row Pointer (Address of TBLROW)
* R8 = Table Row Counter
* ---------------------------------------------------------------------
CHKTBL   EQU   *
         CIJNH R8,0,ERR_NOTFND     Exit if table rows exhausted
         
         USING TBLROW,R7           Map row structure
         L     R9,TOKARRPTR        R9 = Reset pointer to start of Input String
         LA    R5,ROWTEXT          R5 = Pointer to start of current Row Text
*
STRIDELP EQU   *
         VL    V1,0(,R9)           Load 16 bytes of Input String into V1
         VL    V2,0(,R5)           Load 16 bytes of Row String into V2
*
* Compare V1 and V2 byte-by-byte. 
* 'Z' searches for a null (\0) terminator in both registers.
* 'S' updates the Condition Code (CC) to describe the exact result.
         VFEEBS V3,V1,V2,Z
*
* Condition Code Meanings for VFEEBS with Z modifier:
* CC=0 : No elements equal, and no zero elements found (Complete Mismatch)
* CC=1 : Element equal found at an index lower than any zero element (Partial Match)
* CC=2 : A zero element was found at an index lower than or equal to any unequal element
* CC=3 : All elements equal, and no zero elements found (Stride Matched, continue)
*
         BC    2,STRIDE_CONT       Mask 2 (CC=3): 16-byte match, no \0. Next stride!
         BC    4,CHECK_END         Mask 4 (CC=2): Zero/Null found! Verify final match.
*
* If CC=0 or CC=1, it means a mismatch occurred before hitting a string end.
NEXTROW  EQU   *
         L     R7,ROWNEXT          Follow pointer to next row DSECT
         AHI   R8,-1               Decrement row counter
         J     CHKTBL              Jump back to top of table evaluation
*
STRIDE_CONT EQU *
         LA    R9,16(,R9)          Advance Input String address by 16 bytes
         LA    R5,16(,R5)          Advance Row String address by 16 bytes
         J     STRIDELP            Process next 16-byte stride
*
CHECK_END EQU  *
* We found a null terminator. We must verify that BOTH strings terminated 
* at the exact same index to confirm a true equality match.
* V3 contains the byte index (0-15) where the condition met.
         VLGVB R1,V3,7             Extract the match index byte into GPR1
         AR    R9,R1               Point to final matching character/null in Input
         AR    R5,R1               Point to final matching character/null in Row
         LLC   R2,0(,R9)           Load byte from Input String
         LLC   R4,0(,R5)           Load byte from Row String
         CRJNE R2,R4,NEXTROW       If they don't match (e.g. one string ended early), fail.
*
MATCHED  EQU   *
*        ... Handle successful match found at address in R7 ...
