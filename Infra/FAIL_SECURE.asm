*---------------------------------------------------------------------*
* CONSOLE FAILURE EXIT: ROUTE LOG METRICS DIRECTLY TO SYSTEM LOGGER   *
*---------------------------------------------------------------------*
FAIL_SECURE EQU *
         MVI   BOOL_OUT,X'00'      Force boolean status to false
         
* Connect / Open the MVS Log Stream
         IXGCONN REQUEST=CONNECT,                                      *
               STREAMNAME=STRM_NAME,                                   *
               STREAMTOKEN=STRM_TOKEN,                                 *
               RETCODE=L_RC,                                           *
               RSNCODE=L_RSN
               
         LTR   R15,R15             Did we connect to IXGLOGR?
         BNZ   JUST_WIPE           If connection fails, skip log write
         
* Load Data Vector and push record to log stream buffer
         LA    R2,SMF_REC          Reuse formatted data block pointer
         LA    R3,SMF_HDR_LN       Length of diagnostic data record
         
         IXGWRITE REQUEST=WRITE,                                       *
               STREAMTOKEN=STRM_TOKEN,                                 *
               BUFFER=(R2),                                            *
               BUFFLEN=(R3),                                           *
               RETCODE=L_RC,                                           *
               RSNCODE=L_RSN
               
* Disconnect from System Logger safely before wiping environment
         IXGCONN REQUEST=DISCONNECT,                                   *
               STREAMTOKEN=STRM_TOKEN,                                 *
               RETCODE=L_RC,                                           *
               RSNCODE=L_RSN

JUST_WIPE EQU *
         BAL   R10,DESTRUCT_DSN    Invoke SVC 99 self-destruct sequence
         ABEND 911,DUMP            Hard crash the thread

*---------------------------------------------------------------------*
* CONSTANTS AND WORKAREA EXTENSIONS                                   *
*---------------------------------------------------------------------*
STRM_NAME DC   CL26'SYSPLEX.SSL.ERROR.LOG'
         
* Append to WORKAREA DSECT:
* STRM_TOKEN DS   CL16             Token returned by connection step
* L_RC       DS   F                System Logger Return Code
* L_RSN      DS   F                System Logger Reason Code
