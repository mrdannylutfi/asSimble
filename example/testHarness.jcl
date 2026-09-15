//ASMDRV   JOB (ACCT),'COMPILE DRIVER',CLASS=A,MSGCLASS=X,NOTIFY=&SYSUUID
//*-------------------------------------------------------------------*
//* STEP 1: ASSEMBLE THE MOCK DRIVER AND TABLE BUILDER ROUTINE
//*-------------------------------------------------------------------*
//ASM      EXEC PGM=ASMA90,
//             PARM='OBJECT,RENT,GOFF,LIST,XREF(SHORT)'
//SYSLIB   DD  DISP=SHR,DSN=SYS1.MACLIB
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(5,5))
//SYSPRINT DD  SYSOUT=*
//SYSLIN   DD  DISP=(NEW,PASS),UNIT=SYSDA,SPACE=(CYL,(1,1)),
//             DSN=&&DRVOBJ,DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120)
//SYSIN    DD  *
* --- INSERT THE ENTIRE 'DRVPROG' AND 'BLDTBL' CODE STREAM HERE ---
/*
//*-------------------------------------------------------------------*
//* STEP 2: BIND THE DRIVER EXECUTABLE
//*-------------------------------------------------------------------*
//BIND     EXEC PGM=IEWBLINK,
//             PARM='RENT,REUS,AMODE=31,RMODE=ANY'
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(2,2))
//SYSLIB   DD  DISP=SHR,DSN=YOUR.PROGLIB.PDSE
//SYSLMOD  DD  DISP=SHR,DSN=YOUR.PROGLIB.PDSE(DRVPROG)
//SYSLIN   DD  *
  INCLUDE DRVOBJ
  ENTRY DRVPROG
  NAME DRVPROG(R)
/*
