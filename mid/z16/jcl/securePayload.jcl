//SECUREXQ JOB (ACCT),'TEST CPACF RUN',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//             NOTIFY=&SYSUUID
//*
//*-------------------------------------------------------------------*
//* STEP 1: PRE-ALLOCATE THE TARGET DATASET FOR THE TEST              *
//*         This creates the file that our program will delete        *
//*         if the security checks or password fail.                  *
//*-------------------------------------------------------------------*
//PREALLOC EXEC PGM=IEFBR14
//TARGETDS DD DSN=SYS1.SECURE.PAYLOAD.OUT,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=80),
//            UNIT=SYSALLDA
//*
//*-------------------------------------------------------------------*
//* STEP 2: ASSEMBLE AND LINK-EDIT THE z16 HLASM CODE                  *
//*-------------------------------------------------------------------*
//ASMBL    EXEC ASMACL,PARM.ASM='OBJECT,LIST',PARM.LKED='LIST,XREF'
//ASM.SYSIN DD *
*---------------------------------------------------------------------*
* SECURE TRIAL & EXCEPTION ENCAPSULATION WITH CPACF & SVC 99 EXPANSION*
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
* 1. ESTABLISH EXCEPTION TRAP (TRY BLOCK)                             *
*---------------------------------------------------------------------*
         ESTAEX RECOVERY_ROUTINE,PARAM=(R11) Set up exception trap
         ST    R1,ESTAE_TOKEN      Save token for termination
         
*---------------------------------------------------------------------*
* 2. THREE-FACTOR SECURITY VALIDATION                                 *
*---------------------------------------------------------------------*
* [FACTOR 1: AUTHENTICATION] 
         L     R3,PSAAOLD-PSA(0)   Get ASCB pointer
         L     R3,ASCBASXB-ASCB(R3) Get ASXB
         L     R4,ASXBACEE-ASXB(R3) Get SAF ACEE token
         LTR   R4,R4               Is user authenticated?
         BZ    FAIL_SECURE         No -> Self-destruct

* [FACTOR 2: AUTHORIZATION]
         RACROUTE REQUEST=AUTH,CLASS='FACILITY',ENTITY='SECURE.PAYLOAD',*
               ATTR=UPDATE,WORKA=RACF_WORK
         LTR   R15,R15             Is user authorized?
         BNZ   FAIL_SECURE         No -> Self-destruct

* [FACTOR 3: PASSWORD VALIDATION]
         CLC   INPUT_PWD,VALID_PWD  Right password?
         BNE   FAIL_SECURE         No -> Self-destruct

*---------------------------------------------------------------------*
* 3. AES-256 CPACF DECRYPTION STEP (UNHIDE THE BOOLEAN)               *
*---------------------------------------------------------------------*
         MVC   CPACF_KEY,SECURE_KEY     Copy 32-byte key to workarea
         MVC   CPACF_IV,SECURE_IV       Copy 16-byte IV to workarea
         
         LA    R0,18                    Function code: AES-256
         LA    R1,CPACF_PARM            R1 points to Key/IV block
         LA    R2,PLAIN_TXT             R2 points to output buffer
         LA    R3,16                    R3 = Length of data (1 block)
         LA    R4,CIPHER_TXT            R4 points to encrypted boolean
         
         KM    R2,R4                    Decrypt CIPHER_TXT into PLAIN_TXT
         
         MVC   BOOL_OUT,PLAIN_TXT       Extract the boolean status byte
         
         BAL   R10,WRITE_OUTPUT         Safely export/process result
         B     EXIT_NORMAL              Clean up and exit

*---------------------------------------------------------------------*
* CATCH & FAIL PATHS                                                  *
*---------------------------------------------------------------------*
RECOVERY_ROUTINE Routine
         USING *,R15
         L     R11,0(,R1)          Reload workarea pointer
         DROP  R15
         B     FAIL_SECURE

FAIL_SECURE EQU *
         MVI   BOOL_OUT,X'00'      Zero out output variable
         BAL   R10,DESTRUCT_DSN    Invoke SVC 99 self-destruct sequence
         ABEND 911,DUMP            Hard crash the thread

EXIT_NORMAL EQU *
         ESTAEX 0,TOKEN=ESTAE_TOKEN Remove trap
         PR                        Return

*---------------------------------------------------------------------*
* EXPANDED SVC 99 DATASET SELF-DESTRUCT SUBROUTINE                    *
*---------------------------------------------------------------------*
DESTRUCT_DSN EQU *
         XC    S99RBP,S99RBP       Clear pointer block
         XC    S99RB(S99RBLEN),S99RB Clear request block
         
         LA    R1,S99RB
         ST    R1,S99RBP           Set pointer to RB
         OI    S99RBP,X'80'        Set high-order bit (end of list)
         
         MVI   S99RBLN,S99RBLEN    Set RB length
         MVI   S99VERB,S99VRBUN    Verb = Unallocation
         
         LA    R2,TU_DSNAME
         ST    R2,TU_PTR1
         LA    R2,TU_STATUS
         ST    R2,TU_PTR2          Mark final disposition block
         OI    TU_PTR2,X'80'       End of text units array
         
         LA    R2,TU_PTR1
         ST    R2,S99TXTPP         Link text units to Request Block
         
         LA    R1,S99RBP
         SVC   99                  Execute DYNALLOC -> Wipes dataset
         BR    R10

WRITE_OUTPUT EQU *
         BR    R10

*---------------------------------------------------------------------*
* STATIC STORAGE & CRYPTOGRAPHIC CONSTANTS                            *
*---------------------------------------------------------------------*
VALID_PWD  DC    CL8'Z16SYSX!'
INPUT_PWD  DC    CL8'WRONGPWD'     * Simulated bad input triggers delete
         
SECURE_KEY DC    XL32'F1E2D3C4B5A697887766554433221100AABBCCDDEEFF00112233445566778899'
SECURE_IV  DC    XL16'000102030405060708090A0B0C0D0E0F'
CIPHER_TXT DC    XL16'A4C5FE2188B12C33D29011F4A565BC02' 

* Explicit Dynamic Allocation Text Units
         DS    0F
TU_DSNAME  DC    XL2'0001'         Key 0001 = Dataset Name Specification
           DC    XL2'0001'         Number of text elements (1)
           DC    XL2'0016'         Length of DSN string (22 bytes)
           DC    CL22'SYS1.SECURE.PAYLOAD.OUT' Target self-destruct DSN
         
TU_STATUS  DC    XL2'0007'         Key 0007 = Normal/Abnormal Disposition
           DC    XL2'0001'         Number of elements (1)
           DC    XL2'0001'         Length (1 byte)
           DC    XL1'04'           Value 04 = DELETE dataset

*---------------------------------------------------------------------*
* DYNAMIC WORK AREA DSECT                                             *
*---------------------------------------------------------------------*
WORKAREA DSECT
ESTAE_TOKEN DS  F
BOOL_OUT    DS  XL1
RACF_WORK   DS  CL128

            DS  0D
CPACF_PARM  DS  0XL48
CPACF_IV    DS  XL16               16-Byte Initialization Vector
CPACF_KEY   DS  XL32               32-Byte Decryption Key
PLAIN_TXT   DS  XL16               Target transient output block

S99RBP      DS  F
S99RB       DS  CL20
S99TXTPP    DS  F
TU_PTR1     DS  F
TU_PTR2     DS  F

DYNAMIC_DATA EQU *
         IHAASCB
         IHAASXB
         IEFZB4D0
         IHAPSA
         END SECRECOV
/*
//LKED.SYSIN DD *
 NAME SECRECOV(R)
/*
//*
//*-------------------------------------------------------------------*
//* STEP 3: EXECUTE THE SECURE PROGRAM                                 *
//*-------------------------------------------------------------------*
//RUNPROG  EXEC PGM=SECRECOV
//STEPLIB  DD DSN=&&OBJSET,DISP=(OLD,PASS)
//SYSUDUMP DD SYSOUT=*
//
