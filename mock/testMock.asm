DRVPROG  CSECT
DRVPROG  AMODE 31
DRVPROG  RMODE ANY
* =====================================================================
* MOCK DRIVER TEST HARNESS
* =====================================================================
         BAKR  R14,0               Save registers on OS Linkage Stack
         BALR  R12,0               Establish base register for test driver
         USING *,R12
*
* Allocate a heap block to construct our dynamic table model
         STORAGE OBTAIN,LENGTH=2048,ADDR=(R4),COND=NO,LOC=ANY
         LR    R10,R4              R10 = Retain anchor address of heap memory
*
* Initialize Table Head Counter Area
         MVC   0(4,R10),=F'2'      We will construct exactly 2 entries in table
         LA    R4,4(,R10)          Advance heap pointer past row count element
         LA    R11,0               Clear tracking pointer (no previous entry yet)
*
* ---------------------------------------------------------------------
* BUILD ROW 1: Text = "TARGET_ITEM_ALPHA\0", Payload = X'00000A1A'
* ---------------------------------------------------------------------
         LA    R2,=A(STR1)         R2 = Point to first source string
         L     R3,=X'00000A1A'     R3 = Assign payload identifier
         BAL   R14,BLDTBL          Build the structure row
*
* ---------------------------------------------------------------------
* BUILD ROW 2: Text = "TARGET_ITEM_BETA\0",  Payload = X'00000B2B'
* ---------------------------------------------------------------------
         LA    R2,=A(STR2)         R2 = Point to second source string
         L     R3,=X'00000B2B'     R3 = Assign payload identifier
         BAL   R14,BLDTBL          Build the structure row
*
* =====================================================================
* SETUP INPUT ENVTOKEN STRUCTURE PARAMETERS
* =====================================================================
         LA    R9,MYTOKEN          Map local parameter token footprint
         USING ENVTOKEN,R9
*
         LA    R1,=A(SRCHSTR)      Point to our input look-up needle
         ST    R1,TOKARRPTR        Set search pointer criteria
         ST    R10,TOKTBLPTR       Set pointer to table anchor base structure
         LA    R1,DRVOUT           Address of output field inside driver
         ST    R1,TOKOUTPTR        Give matching engine target payload field
*
* =====================================================================
* EXECUTE OPTIMIZED ENGINE MODULE
* =====================================================================
         LA    R1,PARMLIST         Set up parameter list structure register
         ST    R9,PARMLIST         Store token structure reference pointer
*
         LINK  EP=MYPROG           Call the modernized z16 Match Engine
*
* After LINK returns:
* R15 contains the Engine Return Code (0=Match, 4=Not Found, 8=Overrun)
* DRVOUT will contain X'00000B2B' (Payload matching "TARGET_ITEM_BETA")
*
* Clean up heap memory allocations before shutdown
         STORAGE RELEASE,LENGTH=2048,ADDR=(R10),COND=NO
*
         XR    R15,R15             Clear RC for driver exit status
         PR    ,                   Return to OS caller
*
* =====================================================================
* LITERALS, VARIABLES, AND STATIC DEFINITIONS
* =====================================================================
         DS    0F
PARMLIST DS    A                   R1 pointer anchor block
DRVOUT   DS    F                   Target location to receive payload
*
* Sample String Input Buffers
STR1     DC    C'TARGET_ITEM_ALPHA',X'00'
STR2     DC    C'TARGET_ITEM_BETA',X'00'
SRCHSTR  DC    C'TARGET_ITEM_BETA',X'00'   Search Needle (Matches Row 2)
*
* Pre-allocated Static Token Blueprint 
MYTOKEN  DS    XL(16)              Matches size of ENVTOKEN mapping DSECT
