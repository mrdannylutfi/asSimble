 /* ------------------------------------------------------------------- */
/* SUBROUTINE: ALLOCATE AND DROP MAIL INTO CSSMTP SPOOL VIA SYSOUT     */
/* ------------------------------------------------------------------- */
send_smtp_alert: procedure
    parse arg sys_id, bad_date, bad_time
    
    say "!!! CRITICAL: THRESHOLD EXCEEDED. ROUTING TO CSSMTP SPOOL !!!"
    
    /* Allocate directly to the CSSMTP external writer class (typically B) */
    /* Note: Check your local TCP/IP profile for the exact CSSMTP Writer name */
    address TSO "ALLOC FI(CSSMTP) SYSOUT(B) WRITER(CSSMTP) RECFM(F B) LRECL(80)"
    
    if rc \= 0 then do
        say "CRITICAL ERROR: Failed to allocate CSSMTP spool dataset."
        return
    end
    
    /* Standardized RFC 2822 Structure for CSSMTP processing */
    /* Note: AT-TLS policies automatically intercept this traffic and encrypt */
    /* it via TLS/SSL using your RACF Keyring certificates before it leaves z16 */
    mail.1  = "From: z16 Security Intercept Service <sysplex_security@"sys_id".ibm.com>"
    mail.2  = "To: System Administrator <sysadmin@yourcompany.com>"
    mail.3  = "Subject: [CRITICAL] Multiple Security Self-Destruct Triggers on "sys_id
    mail.4  = ""
    mail.5  = "=================================================================="
    mail.6  = "WARNING: SECURITY THRESHOLD BREACH DETECTED VIA CSSMTP"
    mail.7  = "=================================================================="
    mail.8  = "The z16 hardware validation framework has captured multiple"
    mail.9  = "sequential ICSF key generation failures on system: "sys_id
    mail.10 = ""
    mail.11 = "Incident Parameter State:"
    mail.12 = "  - Event Date:     "bad_date
    mail.13 = "  - Detection Time: "bad_time " (System Local)"
    mail.14 = "  - Targeted Action: Dynamic Dataset Self-Destruct (SVC 99) Fired"
    mail.15 = ""
    mail.16 = "Action Required: Review console syslog and audit profiles immediately."
    mail.0  = 16
    
    /* Flush the array directly into the CSSMTP processing engine */
    "EXECIO * DISKW CSSMTP (STEM mail. FINIS"
    address TSO "FREE FI(CSSMTP)"
    return
