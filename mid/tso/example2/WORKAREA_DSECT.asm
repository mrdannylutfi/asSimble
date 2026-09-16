* SMF Logging Layout Area
         DS    0F
SMF_REC   DS    0CL52
SMF_LEN   DS    H                  Record length
SMF_SEG   DS    H                  Segment indicator
SMF_SYS   DS    XL1                System indicator
SMF_RTY   DS    XL1                Record type (128)
SMF_TME   DS    F                  Time from midnight
SMF_DTE   DS    F                  Date stamp
SMF_SYSID DS    CL4                System ID
SMF_MSG   DS    CL32               Detailed warning payload string
SMF_HDR_LN EQU  *-SMF_REC
