//S390COMP JOB (ACCT),'S390 COBOL DB2',
//             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//*-------------------------------------------------------------------*
//* STEP 1: DB2 PRECOMPILE (EXTRACT SQL & CREATE DBRM)               *
//*-------------------------------------------------------------------*
//PRECOMP  EXEC PGM=DSNHPC,REGION=4M,
//         PARM='HOST(COBOL),APOST,APOSTSQL'
//STEPLIB  DD DSN=DSN710.SDSNLOAD,DISP=SHR       <-- Db2 v7 libraries for S/390
//SYSIN    DD DSN=YOUR.COBOL.SOURCE(DB2MRGBT),DISP=SHR
//SYSLIB   DD DSN=YOUR.COPYBOOK.LIB,DISP=SHR
//*--------Output clean COBOL source code with SQL statements stripped out --------
//SYSCPRMD DD DSN=&&PURECOB,DISP=(NEW,PASS),
//            SPACE=(CYL,(1,1)),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120)
//*--------Output the bound DBRM module --------
//BRM      DD DSN=YOUR.TEST.DBRMLIB(DB2MRGBT),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT2   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//*-------------------------------------------------------------------*
//* STEP 2: COBOL COMPILER FOR OS/390                                *
//*-------------------------------------------------------------------*
//COMPILE  EXEC PGM=IGYCRCTL,REGION=4M,
//         PARM='LIST,MAP,XREF,OPTIMIZE'
//STEPLIB  DD DSN=COBOL.SIGYCOMP,DISP=SHR        <-- OS/390 Classic COBOL Compiler
//SYSIN    DD DSN=&&PURECOB,DISP=(OLD,DELETE)
//SYSLIN   DD DSN=&&LOADSET,DISP=(MOD,PASS),
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT2   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT3   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT4   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT5   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT6   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//*-------------------------------------------------------------------*
//* STEP 3: LINK-EDIT (BINDING RUNTIME MODULES)                      *
//*-------------------------------------------------------------------*
//LKED     EXEC PGM=IEWBLINK,REGION=4M,
//         PARM='LIST,LET,XREF'
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR          <-- Classic Language Environment
//         DD DSN=DSN710.SDSNLOAD,DISP=SHR       <-- S/390 Db2 Runtime Support Libraries
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//*-------- The final output Load Module library --------
//SYSLMOD  DD DSN=YOUR.TEST.LOADLIB(DB2MRGBT),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSIN    DD *
 INCLUDE SYSLIB(DSNELI)                         <-- S/390 TSO Classic Db2 Connector
 ENTRY DB2MRGBT
/*
