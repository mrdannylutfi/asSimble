//DB2COMP  JOB (ACCT),'COMPILE COBOL DB2',
//             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//*-------------------------------------------------------------------*
//* STEP 1: COMPILING WITH DB2 COPROCESSOR                           *
//*-------------------------------------------------------------------*
//COMPILE  EXEC PGM=IGYCRCTL,REGION=0M,
//         PARM='SQL,LIST,MAP,XREF,OPTIMIZE(2)'
//STEPLIB  DD DSN=IGY.V6R3M0.SIGYCOMP,DISP=SHR   <-- 您的COBOL编译器库
//         DD DSN=DSN1210.SDSNEXIT,DISP=SHR      <-- 您的Db2 Exit库
//         DD DSN=DSN1210.SDSNLOAD,DISP=SHR      <-- 您的Db2 Load库
//SYSIN    DD DSN=YOUR.COBOL.SOURCE(DB2MRGBT),DISP=SHR
//SYSLIB   DD DSN=YOUR.COPYBOOK.LIB,DISP=SHR
//*-------- 输出的 DBRM 库设置 --------
//DBRMLIB  DD DSN=YOUR.TEST.DBRMLIB(DB2MRGBT),DISP=SHR
//*-----------------------------------
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
//*-------------------------------------------------------------------*
//* STEP 2: LINK-EDIT TO CREATE RUNNABLE LOAD MODULE                 *
//*-------------------------------------------------------------------*
//LKED     EXEC PGM=IEWBLINK,REGION=0M,
//         PARM='LIST,LET,XREF,REUS=RENT'
//STEPLIB  DD DSN=CEE.SCEERUN,DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR          <-- Language Environment
//         DD DSN=DSN1210.SDSNLOAD,DISP=SHR      <-- Db2 运行期支持库
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//*-------- 输出的 运行 Load Module 库 --------
//SYSLMOD  DD DSN=YOUR.TEST.LOADLIB(DB2MRGBT),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSIN    DD *
 INCLUDE SYSLIB(DSNELI)                          <-- 包含Db2 TSO连接模块
 ENTRY DB2MRGBT
/*
