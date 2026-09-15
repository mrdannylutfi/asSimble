* =====================================================================
* Z16 VECTOR STRIDING ROW LAYOUT WITH PAYLOAD (DSECT)
* =====================================================================
TBLROW   DSECT
ROWNEXT  DS    A                 +00  Fullword pointer to next row (31-bit)
ROWFLAGS DS    BL1               +04  Metadata flags
         DS    XL3               +05  Padding to align ROWTEXT perfectly
ROWTEXT  DS    0X                +08  Start of Null-Terminated ASCII Text
*                                     (Variable length, ended by \0)
*                                     Followed by payload at the end of text
ROWPAYLD DS    F                 Offset depends on string size, or can be mapped 
*                                 as a separate structural offset if fixed.
