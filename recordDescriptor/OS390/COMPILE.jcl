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
//*-------- 输出剥离 SQL 后干净的 COBOL 源码 --------
//SYSCPRMD DD DSN=&&PURECOB,DISP=(NEW,PASS),
//            SPACE=(CYL,(1,1)),UNIT=SYSDA,
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120)
//*-------- 输出绑定的 DBRM 模块 --------
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
//STEPLIB  DD DSN=COBOL.SIGYCOMP,DISP=SHR        <-- OS/390 经典 COBOL 编译器
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
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR          <-- 经典 Language Environment
//         DD DSN=DSN710.SDSNLOAD,DISP=SHR       <-- S/390 Db2 运行支持库
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//*-------- 最终输出的运行 Load Module 库 --------
//SYSLMOD  DD DSN=YOUR.TEST.LOADLIB(DB2MRGBT),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSIN    DD *
 INCLUDE SYSLIB(DSNELI)                          <-- S/390 TSO 经典 Db2 连接器
 ENTRY DB2MRGBT
/*
