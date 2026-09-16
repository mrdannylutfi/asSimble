//RUNSTEP  EXEC PGM=DB2MRGBT
//STEPLIB  DD DSN=YOUR.TEST.LOADLIB,DISP=SHR
//         DD DSN=DSN710.SDSNLOAD,DISP=SHR
//*-------------------------------------------------------------------*
//*  Add the input stream for your source file containing 2 million records here.
//*-------------------------------------------------------------------*
//INFILE   DD DSN=TEST.HR.BATCH.EMPINPUT,DISP=SHR,BUFNO=30
//SYSOUT   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
