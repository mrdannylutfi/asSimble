CALLER   CSECT
CALLER   AMODE 31
CALLER   RMODE ANY
* ... Standard Entry Linkage for Caller ...
*
* ---------------------------------------------------------------------
* 1. PREPARE THE DATA AND LOOKUP TABLE FOR THE THREAD
* ---------------------------------------------------------------------
* Assume MYARRAY and MYTABLE are loaded or built in this thread's storage
*
* ---------------------------------------------------------------------
* 2. POPULATE THE CONTEXT TOKEN STRUCTURE
* ---------------------------------------------------------------------
         LA    R2,MYARRAY          Get address of input data array
         ST    R2,MYTOKEN          Store in Token Block offset +0
*
         L     R2,=F'5'            Array has 5 elements
         ST    R2,MYTOKEN+4        Store in Token Block offset +4
*
         LA    R2,MYTABLE          Get address of condition table
         ST    R2,MYTOKEN+8        Store in Token Block offset +8
*
* ---------------------------------------------------------------------
* 3. LINK TO THE REFACTORED SUBROUTINE VIA BALR
* ---------------------------------------------------------------------
         LA    R1,MYTOKEN          R1 points to the Context Token structure
         L     R15,=V(MYPROG)      Load V-con of the target routine
         BALR  R14,R15             Branch and Link to MYPROG (Return via R14)
*
* --- Upon return, R15 contains the calculated thread total ---
* ... Standard Exit Linkage for Caller ...
*
* ---------------------------------------------------------------------
* READ-ONLY OR THREAD-ALLOCATED STORAGE IN CALLER
* ---------------------------------------------------------------------
         DS    0F
MYARRAY  DC    F'10',F'200',F'500',F'20',F'100'  Sample data
*
* Static or Dynamic lookup table matching the target routine
MYTABLE  DS    0F
         DC    F'3'                Number of lookup entries in table
         DC    F'100',F'50'        Row 1: If 100, add 50
         DC    F'200',F'100'       Row 2: If 200, add 100
         DC    F'300',F'150'       Row 3: If 300, add 150
*
* The Parameter Structure passed to the target routine
         DS    0F
MYTOKEN  DS    A                   Pointer to Array (+0)
         DS    F                   Number of Elements (+4)
         DS    A                   Pointer to Table (+8)
*
         END   CALLER
