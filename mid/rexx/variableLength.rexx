/* REXX - Parse and Format Custom SMF Type 128 Security Logs */
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

do i = 1 to rec.0
    current_row = rec.i
    
    /* Offset adjustments mapping directly to HLASM WORKAREA layout */
    /* SMF records read via EXECIO contain the 4-byte RDW header    */
    
    record_type = c2d(substr(current_row, 6, 1))
    
    if record_type = 128 then do
        /* Extract Time (Binary hundredths of a second since midnight) */
        raw_time = c2d(substr(current_row, 7, 4))
        formatted_time = format_smf_time(raw_time)
        
        /* Extract Date (Packed decimal: 0CYYDDDF) */
        raw_date = c2x(substr(current_row, 11, 4))
        formatted_date = format_smf_date(raw_date)
        
        /* Extract System ID and Custom String Payload */
        sys_id  = strip(substr(current_row, 15, 4))
        msg_txt = strip(substr(current_row, 19, 32))
        
        /* Print formatted audit entry */
        say left(formatted_time, 19) left(formatted_date, 10) ,
            left(sys_id, 10) msg_txt
    end
end
exit 0

/* Subroutine to convert SMF binary time to HH:MM:SS.th format */
format_smf_time: procedure
    parse arg hundredths
    seconds = hundredths // 100
    total_secs = hundredths % 100
    hh = total_secs % 3600
    mm = (total_secs // 3600) % 60
    ss = total_secs // 60
    return right(hh,2,'0')":"right(mm,2,'0')":"right(ss,2,'0')
    
/* Subroutine to convert SMF packed date (Packed Decimal) to YYYY/DDD */
format_smf_date: procedure
    parse arg hex_date
    /* Extract digits ignoring the sign nibble 'F' or 'C' */
    century_indicator = substr(hex_date, 2, 1)
    year = substr(hex_date, 3, 2)
    day  = substr(hex_date, 5, 3)
    
    if century_indicator = '1' then full_year = "20"year
    else full_year = "19"year
    
    return full_year"/"day
