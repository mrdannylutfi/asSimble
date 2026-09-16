*---------------------------------------------------------------------*
* CUSTOM SECURITY EXPLICIT REPORTING EXIT (SMF RECORDING)              *
*---------------------------------------------------------------------*
FAIL_SECURE EQU *
         MVI   BOOL_OUT,X'00'      Force boolean status to false
         
* Check if failure was caused by ICSF (R15 non-zero from the service)
         LTR   R15,R15
         BZ    JUST_WIPE           If R15=0, skip logging and wipe
         
* Format and write custom SMF User Record (Type 128)
         XC    SMF_REC(SMF_HDR_LN),SMF_REC Clear SMF buffer area
         LA    R2,SMF_HDR_LN       Get length of total block
         STH   R2,SMF_LEN          Offset 00: Total record length
         STH   0,SMF_SEG           Offset 02: Segment descriptor (0000)
         MVI   SMF_SYS,X'02'       Offset 04: System flag
         MVI   SMF_RTY,128         Offset 05: SMF User Record Type 128
         
         TIME  BIN                 Get exact time and date stamps
         ST    R0,SMF_TME          Offset 06: Time since midnight
         ST    R1,SMF_DTE          Offset 10: Date stamp
         
         MVC   SMF_SYSID,=CL4'Z16S' Offset 14: System Identifier (z16)
         MVC   SMF_MSG,=CL32'SECURITY ERROR: CSNBKGN KEY GEN FAILED'
         
         * Write record to the system audit stream via SMF service
         SMFEWTM MSGAD=SMF_REC
         
JUST_WIPE EQU *
         BAL   R10,DESTRUCT_DSN    Invoke SVC 99 self-destruct sequence
         ABEND 911,DUMP            Hard crash the thread
