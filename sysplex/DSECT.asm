*---------------------------------------------------------------------*
* TBLROW - Variable Payload Table Row Layout                          *
*---------------------------------------------------------------------*
TBLROW   DSECT 
TBLROWNEXT DS  A'0'            00-03 Fullword pointer to next row (31-bit)
ROWFLAGS   DS  BL1             04    Operational flags
           DS  XL1             05    Alignment padding (reserved)
ROWPLEN    DS  H               06-07 Length of variable payload data (1-based)
ROWTEXT    DS  0X              08    Start of Null-Terminated String Data
*                              (String ends with X'00'; variable 
*                               payload data follows immediately after)
TBLROW_LEN EQU *-TBLROW        Length of fixed header portion
