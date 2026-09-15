//ASMENGINE JOB (ACCT),'COMPILE ENGINE',CLASS=A,MSGCLASS=X,NOTIFY=&SYSUUID
//*-------------------------------------------------------------------*
//* STEP 1: ASSEMBLE THE Z16 ACCELERATED MATCH ENGINE
//*-------------------------------------------------------------------*
//ASM      EXEC PGM=ASMA90,
//             PARM='OBJECT,RENT,GOFF,LIST,XREF(SHORT),OPT(1)'
//SYSLIB   DD  DISP=SHR,DSN=SYS1.MACLIB
//*        DD  DISP=SHR,DSN=YOUR.CUSTOM.MACLIB (IF DSECTS ARE IN MACROS)
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(5,5))
//SYSPRINT DD  SYSOUT=*
//SYSLIN   DD  DISP=(NEW,PASS),UNIT=SYSDA,SPACE=(CYL,(1,1)),
//             DSN=&&ENGOBJ,DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120)
//SYSIN    DD  *
* --- INSERT THE ENTIRE 'MYPROG' CODE STREAM HERE ---
/*
//*-------------------------------------------------------------------*
//* STEP 2: BIND INTO A PROGRAM OBJECT (PDSE LOAD LIBRARY)
//*-------------------------------------------------------------------*
//BIND     EXEC PGM=IEWBLINK,
//             PARM='RENT,REUS,AMODE=31,RMODE=ANY,CASE=MIXED'
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(2,2))
//SYSLMOD  DD  DISP=SHR,DSN=YOUR.PROGLIB.PDSE(MYPROG)
//SYSLIN   DD  *
  INCLUDE ENGOBJ
  ENTRY MYPROG
  NAME MYPROG(R)
/*
