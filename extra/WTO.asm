*---------------------------------------------------------------------*
* CONSOLE MASTER ACTION INTERCEPT TRIGGER (WTO VIA ROUTING CODE 1)     *
*---------------------------------------------------------------------*
FAIL_SECURE EQU *
         MVI   BOOL_OUT,X'00'      Force boolean status to false
         
* Check if failure was caused by ICSF (R15 non-zero from the service)
         LTR   R15,R15
         BZ    JUST_WIPE           If R15=0, skip logging and wipe
         
* Trigger Dynamic High-Priority Console Alert to Data Center Operators
         WTO   'SEC001E CRITICAL: MULTIPLE ICSF KEY GENERATION FAILURES - *
               DATASET SELF-DESTRUCT INITIATED',                       *
               ROUTCDE=(1),                                            *
               DESC=(1)
               
* Proceed with writing custom SMF records
         XC    SMF_REC(SMF_HDR_LN),SMF_REC
         ... (rest of your existing SMF logging logic) ...
