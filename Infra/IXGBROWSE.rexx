/* REXX - Connect, Browse, and Parse SYSPLEX.SSL.ERROR.LOG via IXGBROWSE */
stream_name = "SYSPLEX.SSL.ERROR.LOG"
token       = copies('00'x, 16)      /* Storage for Connection Token */
br_token    = copies('00'x, 16)      /* Storage for Browse Token     */
rc_code     = 0
rsn_code    = 0

say "=================================================================="
say "         SYSPLEX CF LOGGER FORENSIC EXTRACTION ENGINE             "
say "=================================================================="
say "Target Log Stream: " stream_name

/* STEP 1: CONNECT TO THE SYSPLEX LOG STREAM */
address LINKMVS "IXGCONN REQUEST=CONNECT STREAMNAME=stream_name" ,
                "STREAMTOKEN=token RETCODE=rc_code RSNCODE=rsn_code"

if rc_code \= 0 then do
    say "CRITICAL ERROR: IXGCONN Connect Failed. RC="rc_code "RSN="c2x(rsn_code)
    exit rc_code
end

/* STEP 2: INITIALIZE THE BROWSE SESSION FROM THE OLDEST RECORD */
address LINKMVS "IXGBROWSE REQUEST=START STREAMTOKEN=token" ,
                "BROWSETOKEN=br_token STARTPOS=OLDEST" ,
                "RETCODE=rc_code RSNCODE=rsn_code"

if rc_code \= 0 then do
    say "INFO: Log stream empty or Browse initialization failed."
    signal CLEANUP
end

/* STEP 3: LOG STREAM READ LOOP */
buffer = copies('00'x, 32760)        /* Allocate max data payload block */
buf_len = 32760

say "Timestamp            Date       System ID  Parsed Security Event"
say "-------------------  ---------  ---------  -----------------------"

do forever
    /* Read next sequential record out of the Coupling Facility cache */
    address LINKMVS "IXGBROWSE REQUEST=READNEXT STREAMTOKEN=token" ,
                    "BROWSETOKEN=br_token BUFFER=buffer BUFLEN=buf_len" ,
                    "RETCODE=rc_code RSNCODE=rsn_code"
                    
    /* Break out of loop when end of log stream data is encountered (RC=4) */
    if rc_code = 4 then leave 
    
    if rc_code \= 0 then do
        say "ERROR: IXGBROWSE Read failed. RC="rc_code "RSN="c2x(rsn_code)
        leave
    end
    
    /* MVS Log Stream data parsing block */
    /* Headers mirror the HLASM dynamic SMF layout fields exactly */
    rec_type = c2d(substr(buffer, 2, 1)) 
    
    if rec_type = 128 then do
        raw_time = c2d(substr(buffer, 3, 4))
        fmt_time = format_time(raw_time)
        
        raw_date = c2x(substr(buffer, 7, 4))
        fmt_date = format_date(raw_date)
        
        sys_id   = strip(substr(buffer, 11, 4))
        msg_txt  = strip(substr(buffer, 15, 32))
        
        say left(fmt_time, 19) left(fmt_date, 10) left(sys_id, 10) msg_txt
    end
end

/* STEP 4: SHUT DOWN BROWSE AND DISCONNECT ENVIRONMENT SAFEGUARDS */
address LINKMVS "IXGBROWSE REQUEST=END STREAMTOKEN=token BROWSETOKEN=br_token"

CLEANUP:
address LINKMVS "IXGCONN REQUEST=DISCONNECT STREAMTOKEN=token"
exit 0

/* Time Translation Helper */
format_time: procedure
    parse arg hundredths
    total_secs = hundredths % 100
    return right(total_secs%3600,2,'0')":"right((total_secs//3600)%60,2,'0')":"right(total_secs//60,2,'0')

/* Date Translation Helper */
format_date: procedure
    parse arg hex_date
    if substr(hex_date, 2, 1) = '1' then cc = "20"
    else cc = "19"
    return cc||substr(hex_date, 3, 2)"/"substr(hex_date, 5, 3)
