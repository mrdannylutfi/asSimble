//ALLINONE JOB (ACCT),'MVS TO DB2 STREAM',
//             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//*===================================================================*
//* STEP 1: DB2 PRECOMPILE & COBOL COMPUTE FOR S/390                  *
//*===================================================================*
//COMPILE  EXEC PGM=IGYCRCTL,REGION=4M,
//         PARM='SQL,LIST,MAP,XREF,OPTIMIZE(2)'
//STEPLIB  DD DSN=IGY.V6R3M0.SIGYCOMP,DISP=SHR
//         DD DSN=DSN1210.SDSNEXIT,DISP=SHR
//         DD DSN=DSN1210.SDSNLOAD,DISP=SHR
//SYSIN    DD DSN=YOURHLQ.COBOL.SOURCE(DB2MRGBT),DISP=SHR
//DBRMLIB  DD DSN=YOURHLQ.TEST.DBRMLIB(DB2MRGBT),DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(MOD,PASS),
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT2   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT3   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT4   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT5   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT6   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSUT7   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//*===================================================================*
//* STEP 2: LINK-EDIT TO LOAD LIBRARY                                 *
//*===================================================================*
//LKED     EXEC PGM=IEWBLINK,REGION=4M,PARM='LIST,LET,XREF'
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=DSN1210.SDSNLOAD,DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//SYSLMOD  DD DSN=YOURHLQ.TEST.LOADLIB(DB2MRGBT),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSIN    DD *
 INCLUDE SYSLIB(DSNELI)
 ENTRY DB2MRGBT
/*
//*
//*===================================================================*
//* STEP 3: DB2 BIND PACKAGE FOR 2,000,000 RECORDS                     *
//*===================================================================*
//BINDPKG  EXEC PGM=IKJEFT01,REGION=4M
//STEPLIB  DD DSN=DSN1210.SDSNLOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DB2T)
 BIND PACKAGE(TESTCOLL)                  +
      MEMBER(DB2MRGBT)                   +
      ACT(REPLACE)                       +
      ISOLATION(CS)                      +
      CURRENTDATA(NO)                    +
      RELEASE(COMMIT)                    +
      DEFER(PREPARE)
 END
/*
//*
//*===================================================================*
//* STEP 4: EXECUTE THE COBOL BATCH (2 MILLION DATA SYNC)             *
//*===================================================================*
//RUNBATCH EXEC PGM=IKJEFT01,REGION=4M
//STEPLIB  DD DSN=YOURHLQ.TEST.LOADLIB,DISP=SHR
//         DD DSN=DSN1210.SDSNLOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//*-------------------------------------------------------------------*
//* 🛠️ 这里是您的 200万数据大机源文件输入流 (带 BUFNO=30 异步预读调优)
//*-------------------------------------------------------------------*
//INFILE   DD DSN=YOURHLQ.TEST.DATA.EMPINPUT,DISP=SHR,BUFNO=30
//SYSOUT   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DB2T)
 RUN PROGRAM(DB2MRGBT) PLAN(YOURPLAN) -
     LIB('YOURHLQ.TEST.LOADLIB')
 END
/*
