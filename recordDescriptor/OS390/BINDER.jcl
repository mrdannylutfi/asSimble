//BINDS390 JOB (ACCT),'S390 BIND PACKAGE',
//             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//BINDSTEP EXEC PGM=IKJEFT01,REGION=4M
//STEPLIB  DD DSN=DSN710.SDSNLOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DB2T)                                 
 
 BIND PACKAGE(TESTCOLL)                  +       
      MEMBER(DB2MRGBT)                   +       
      ACT(REPLACE)                       +       
      ISOLATION(CS)                      +       
      CURRENTDATA(NO)                    +       
      RELEASE(COMMIT)                    +       
      DEFER(PREPARE)                            <-- Optimized for S/390: Defer SQL compilation to save network and memory

 END
/*
