*---------------------------------------------------------------------*
* SECURE TRIAL & EXCEPTION ENCAPSULATION WITH DATASET SELF-DESTRUCT   *
*---------------------------------------------------------------------*
SECRECOV CSECT ,
SECRECOV AMODE 31
SECRECOV RMODE ANY
         BAKR  R14,0               Save registers on linkage stack
         BASR  R12,0               Establish base register
         USING *,R12
         
         LA    R11,DYNAMIC_DATA    Establish dynamic work area
         USING WORKAREA,R11
         
*---------------------------------------------------------------------*
* 1. TRY BLOCK: Establish Exception Trap (IBM equivalent to try-catch)*
*---------------------------------------------------------------------*
         ESTAEX RECOVERY_ROUTINE,PARAM=(R11) Set up the "try" block
         ST    R1,ESTAE_TOKEN      Save token for deletion later

*---------------------------------------------------------------------*
* 2. SECURITY CHECKS (Authentication, Authorization, & Password)    *
*---------------------------------------------------------------------*
* [FACTOR 1: AUTHENTICATION] - Verify identity via ACEE (ACF/RACF)
         L     R3,PSAAOLD-PSA(0)   Get current TCB/ASCB pointer
         L     R3,ASCBASXB-ASCB(R3) Get ASXB
         L     R4,ASXBACEE-ASXB(R3) Get ACEE (Accessor Environment Element)
         LTR   R4,R4               Is user authenticated? (ACEE exists)
         BZ    FAIL_SECURE         No -> Trigger Fail/Destruct

* [FACTOR 2: AUTHORIZATION] - SAF Check (RACROUTE) for Access Authority
         RACROUTE REQUEST=AUTH,CLASS='FACILITY',ENTITY='SECURE.PAYLOAD',*
               ATTR=UPDATE,WORKA=RACF_WORK
         LTR   R15,R15             Is user authorized?
         BNZ   FAIL_SECURE         No -> Trigger Fail/Destruct

* [FACTOR 3: PASSWORD VALIDATION] - Compare input password to hash/store
         CLC   INPUT_PWD,VALID_PWD  Does password match?
         BNE   FAIL_SECURE         No -> Trigger Fail/Destruct

*---------------------------------------------------------------------*
* SUCCESS PATH: Hide & Write the Boolean Result                       *
*---------------------------------------------------------------------*
         MVI   BOOL_OUT,X'01'      Set hidden output to TRUE (Valid)
         BAL   R10,WRITE_OUTPUT    Go write to dataset safely
         B     EXIT_NORMAL         Skip recovery cleanup and leave

*---------------------------------------------------------------------*
* CATCH BLOCK: If an Abend Occurs, Control Lands Here Safely          *
*---------------------------------------------------------------------*
RECOVERY_ROUTINE Routine
         USING *,R15
         L     R11,0(,R1)          Reload workarea pointer from PARAM
         DROP  R15
         * Abends caught here will immediately route to self-destruct
         B     FAIL_SECURE         Enforce absolute zero-trust

*---------------------------------------------------------------------*
* FAIL PATH: Self-Destruct Output Dataset                             *
*---------------------------------------------------------------------*
FAIL_SECURE EQU *
         MVI   BOOL_OUT,X'00'      Set hidden output to FALSE
         BAL   R10,DESTRUCT_DSN    CATCH/FAIL: Delete target dataset!
         ABEND 911,DUMP            Hard terminate task

*---------------------------------------------------------------------*
* CLEANUP & EXIT                                                      *
*---------------------------------------------------------------------*
EXIT_NORMAL EQU *
         ESTAEX 0,TOKEN=ESTAE_TOKEN Remove the exception trap
         PR                        Return to caller via linkage stack

*---------------------------------------------------------------------*
* DATASET SELF-DESTRUCT SUBROUTINE (SVC 99 DYNAMIC ALLOCATION)        *
*---------------------------------------------------------------------*
DESTRUCT_DSN EQU *
         XC    S99RBP(S99RBLEN),S99RBP Clear Request Block Pointer
         XC    S99RB(S99RBLEN),S99RB   Clear Request Block
         
         LA    R1,S99RB
         ST    R1,S99RBP           Point pointer to RB
         OI    S99RBP,X'80'        Mark end of pointer list
         
         MVI   S99RBLN,S99RBLEN    Set RB length
         MVI   S99VERB,S99VRBUN    Verb = Unallocation (De-alloc)
         
         * Build text units for Dataset Name and DISP=(,,DELETE)
         LA    R2,TU_LIST
         ST    R2,S99TXTPP         Point RB to Text Unit List
         
         LA    R1,S99RBP
         SVC   99                  Invoke Dynamic Allocation to DELETE
         BR    R10

WRITE_OUTPUT EQU *
         * Standard Record-level OPEN, PUT (BOOL_OUT), CLOSE logic here
         BR    R10

*---------------------------------------------------------------------*
* STATIC STORAGE                                                      *
*---------------------------------------------------------------------*
VALID_PWD DC    CL8'Z16SYSX!'       The valid system password
INPUT_PWD DC    CL8'WRONGPWD'       Simulated user input (Fails check)

*---------------------------------------------------------------------*
* DYNAMIC WORK AREA DSECT (Allocated in Storage)                      *
*---------------------------------------------------------------------*
WORKAREA DSECT
ESTAE_TOKEN DS  F
BOOL_OUT    DS  XL1                 The hidden Boolean payload output
RACF_WORK   DS  CL128
* SVC 99 Structure for Self-Destruct
S99RBP      DS  F
S99RB       DS  CL20
S99TXTPP    DS  F
TU_LIST     DS  3F                  Text unit pointers
DYNAMIC_DATA EQU *
         
         IHAASCB                   Mapping for ASCB
         IHAASXB                   Mapping for ASXB
         IEFZB4D0                  Mapping for SVC 99 DYNALLOC
         IHAPSA                    Mapping for Prefixed Storage Area
         END SECRECOV
