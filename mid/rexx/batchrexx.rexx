//SMFEXTR  JOB (ACCT),'EXTRACT TYPE 128',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//             NOTIFY=&SYSUUID
//*
//*-------------------------------------------------------------------*
//* STEP 1: EXTRACT TYPE 128 USER RECORDS VIA IFASMFDP                *
//*-------------------------------------------------------------------*
//DUMP128  EXEC PGM=IFASMFDP
//INDD     DD DSN=SYS1.MANA,DISP=SHR      <-- Point to active SMF data
//         DD DSN=SYS1.MANB,DISP=SHR
//OUTDD    DD DSN=&&RAW128,DISP=(NEW,PASS),
//            SPACE=(TRK,(5,5),RLSE),
//            DCB=(RECFM=VBS,LRECL=32760,BLKSIZE=0),
//            UNIT=SYSALLDA
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 INDD(INDD,OPTIONS(DUMP))
 OUTDD(OUTDD,TYPE(128))                   <-- Only pull our Type 128 records
/*
//*
//*-------------------------------------------------------------------*
//* STEP 2: RUN THE REXX PARSER TO FORMAT AND PRINT DATA               *
//*-------------------------------------------------------------------*
//PARSE128 EXEC PGM=IKJEFT01,DYNAMNBR=30
//SYSTSPRT DD SYSOUT=*
//SYSEXEC  DD DSN=YOUR.REXX.LIBRARY,DISP=SHR  <-- Target library for REXX code
//SMFDATA  DD DSN=&&RAW128,DISP=(OLD,DELETE)
//SYSTSIN  DD *
  %PARSE128
/*
//
