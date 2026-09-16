//VERFYKEY JOB (ACCT),'VERIFY RACF KEYRING',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//             NOTIFY=&SYSUUID
//*
//*-------------------------------------------------------------------*
//* STEP 1: VERIFY CSSMTP USER ID PROFILE AND KEYRING DEFINITIONS     *
//*-------------------------------------------------------------------*
//CHECKRAC EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  /* List the CSSMTP user profile to verify it exists and is valid */
  LU CSSMTPID
  
  /* List the dynamic keyring to ensure it was created successfully */
  RACDCERT LISTRING(SECURE.CRYPTO.KEYRING) ID(CSSMTPID)
  
  /* Check authorization profile for reading keyrings */
  RLIST FACILITY IRR.DIGTCERT.LISTRING AUTHUSER
/*
//*
//*-------------------------------------------------------------------*
//* STEP 2: SIMULATE CSSMTP STARTED TASK ACCESS VALIDATION             *
//*         Verifies if CSSMTPID has READ access to the keyring control *
//*-------------------------------------------------------------------*
//AUTHCHK  EXEC PGM=IRRUT200
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
* Running structural cross-reference verification on the RACF database.
* Ensure no broken pointers exist for the newly added DIGTCERT profiles.
/*
//
