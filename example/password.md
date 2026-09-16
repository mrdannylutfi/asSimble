## The try Mechanism (ESTAEX): 
ESTAEX registers a recovery routine in the z/OS system intercept queue. 

If any unexpected machine failure or program check occurs during processing, 
the operating system stops the crash, drops execution safely into RECOVERY_ROUTINE,
and forces a jump to FAIL_SECURE.

## Three-Factor Verification Stack:

Authentication: Explicitly checks the z/OS Control Blocks
(`PSA` -> `ASCB` -> `ASXB` -> `ACEE`). 

If the address space doesn't possess a valid Accessor Environment Element token from `SAF` (`System Authorization Facility/RACF`),
it implies an unauthenticated task execution.Authorization: The RACROUTE REQUEST=AUTH macro natively queries the system security manager 
to check if the current user profile has UPDATE rights to the corporate profile resource `(SECURE.PAYLOAD)`.

## Password Validation:

Evaluates INPUT_PWD via a standard `CLC` operation.

## The Self-Destruct Mechanism:
If any component of the three-factor stack fails, or if a structural try macro exception is thrown, execution shifts to FAIL_SECURE. 
It formats `SVC 99` text units using verb S99VRBUN (Dynamic Unallocation) paired with the equivalent of `DISP=(OLD,DELETE)`.
The operating system instantly scratches the catalog entry and unallocates the volume tracks of the `dataset`.
