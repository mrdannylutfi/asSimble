* =====================================================================
* MIXED-SYSPLEX VARIABLE PAYLOAD TABLE ROW LAYOUT (DSECT)
* =====================================================================
TBLROW   DSECT
ROWNEXT  DS    A                 +00 Fullword pointer to next row (31-bit)
ROWFLAGS DS    BL1               +04 Operational flags
         DS    XL1               +05 Alignment padding
ROWPLEN  DS    H                 +06 Length of variable payload data (1-based)
ROWTEXT  DS    0X                +08 Start of Null-Terminated String Data
*                                    (Variable length, ended by \0)
* Variable Payload Data follows immediately after the string \0 terminator.
