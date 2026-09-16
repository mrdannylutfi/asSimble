/* REXX - Parse Custom SMF 128 Logs and Alert Admin on Sequential Failures */
"EXECIO * DISKR SMFDATA (STEM rec. FINIS"
if rc \= 0 then do
    say "Error reading SMF extraction file or no records found."
    exit rc
end

say "=================================================================="
say "           Z16 ICSF KEY GENERATION FAILURE REPORT                "
say "=================================================================="
say "Timestamp            Date       System ID  Message Payload"
say "-------------------  ---------  ---------  -----------------------"

failure_count = 0
alert_triggered = 0

do i = 1 to rec.0
    current_row = rec.i
    record_type = c2d(substr(current_row, 6, 1))
    
    if record_type = 128 then do
        failure_count = failure_count + 1
        
        /* Parse Standard SMF Header Offsets (+4 bytes for RDW) */
        raw_time = c2d(substr(current_row, 7, 4))
        formatted_time = format_smf_time(raw_time)
        
        raw_date = c2x(substr(current_row, 11, 4))
        formatted_date = format_smf_date(raw_date)
        
        sys_id  = strip(substr(current_row, 15, 4))
        msg_txt = strip(substr(current_row, 19, 32))
        
        /* Print record to terminal log */
        say left(formatted_time, 19) left(formatted_date, 10) ,
            left(sys_id, 10) msg_txt
            
        /* Trigger logic: sequential failures within this run block */
        if failure_count >= 3 & alert_triggered = 0 then do
            call send_smtp_alert sys_id, formatted_date, formatted_time
            alert_triggered = 1 /* Prevent flooding if there are many records */
        end
    end
    else do
        /* Reset sequential tracker if an alternate successful block intervenes */
        failure_count = 0 
    end
end
exit 0

/* ------------------------------------------------------------------- */
/* SUBROUTINE: ALLOCATE AND SEND SECURE INTERCEPT SMTP EMAIL          */
/* ------------------------------------------------------------------- */
send_smtp_alert: procedure
    parse arg sys_id, bad_date, bad_time
    
    say "!!! CRITICAL: THRESHOLD EXCEEDED. GENERATING SMTP EMERGENCY ALERT !!!"
    
    /* Dynamically allocate a sysout dataset pointing to the local SMTP reader */
    address TSO "ALLOC FI(SMTP) SYSOUT(A) WRITER(SMTP) RECFM(F B) LRECL(80)"
    
    /* Construct standardized RFC 822 Email Structure */
    mail.1  = "HELO "sys_id
    mail.2  = "MAIL FROM:<sysplex_security@"sys_id".ibm.com>"
    mail.3  = "RCPT TO:<sysadmin@yourcompany.com>"
    mail.4  = "DATA"
    mail.5  = "From: z16 Security Intercept Service <sysplex_security@"sys_id".ibm.com>"
    mail.6  = "To: System Administrator <sysadmin@yourcompany.com>"
    mail.7  = "Subject: [CRITICAL] Multiple Security Self-Destruct Triggers on "sys_id
    mail.8  = ""
    mail.9  = "=================================================================="
    mail.10 = "WARNING: SECURITY THRESHOLD BREACH DETECTED"
    mail.11 = "=================================================================="
    mail.12 = "The z16 hardware validation framework has captured multiple"
    mail.13 = "sequential ICSF key generation failures on system: "sys_id
    mail.14 = ""
    mail.15 = "Incident Parameter State:"
    mail.16 = "  - Event Date:     "bad_date
    mail.17 = "  - Detection Time: "bad_time " (System Local)"
    mail.18 = "  - Targeted Action: Dynamic Dataset Self-Destruct (SVC 99) Fired"
    mail.19 = ""
    mail.20 = "Action Required: Review console syslog and audit profiles immediately."
    mail.21 = "."  /* Period ends DATA chunk */
    mail.22 = "QUIT"
    mail.0  = 22
    
    /* Write to the allocation descriptor */
    "EXECIO * DISKW SMTP (STEM mail. FINIS"
    address TSO "FREE FI(SMTP)"
    return

/* Subroutine to convert SMF binary time to HH:MM:SS format */
format_smf_time: procedure
    parse arg hundredths
    total_secs = hundredths % 100
    hh = total_secs % 3600
    mm = (total_secs // 3600) % 60
    ss = total_secs // 60
    return right(hh,2,'0')":"right(mm,2,'0')":"right(ss,2,'0')
    
/* Subroutine to convert SMF packed date (Packed Decimal) to YYYY/DDD */
format_smf_date: procedure
    parse arg hex_date
    century_indicator = substr(hex_date, 2, 1)
    year = substr(hex_date, 3, 2)
    day  = substr(hex_date, 5, 3)
    if century_indicator = '1' then full_year = "20"year
    else full_year = "19"year
    return full_year"/"day
