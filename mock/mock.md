# Verification Checklist for Testing

## **1. Alignment Verification:**
In a live debugger (such as __z/XDC__ or IBM Developer for __z/OS__), 
set a breakpoint immediately after __BAL R14__,BLDTBL. 
Inspect the address stored inside `R11`.
The last hexadecimal digit of that memory address must always resolve to 0 or 8 to prove successful vector pipelining capability.
## **2. Payload Extraction Inspection:** 
Upon returning from LINK `EP=MYPROG`, verify the contents of the `DRVOUT` storage word. It should cleanly contain `00000B2B` which validates that your text striding mechanism successfully bypasses variable characters, 
correctly terminates at the binary `null` boundaries, and references the appropriate tracking indexes.
