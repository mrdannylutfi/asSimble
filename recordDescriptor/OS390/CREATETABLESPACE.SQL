-- 1. Create a dedicated tablespace
CREATE TABLESPACE TS_EMP
       IN DSNDB04                      --Use the default database for the test environment, or specify your own database.
       USING STOGROUP SYSDEFLT         -- Use the system default storage group
       PRIQTY 40000                    --Primary allocation space (in KB; space reserved for 2 million rows)
       SECQTY 8000                     -- Secondary allocation of space
       LOCKSIZE PAGE                   -- Page-level locking, perfectly aligned with 10,000 COMMITs.
       LOCKMAX SYSTEM                  -- The maximum lock limit is determined by the system.
       CCSID UNICODE                   -- It is recommended to use Unicode encoding.
       COMPRESS YES;                   --  Hardware-level compression on the mainframe must be enabled to reduce I/O overhead.

--2. Create the target employee table (Employee Table)
CREATE TABLE EMPLOYEE (
    EMP_ID     CHAR(10)      NOT NULL,
    EMP_NAME   VARCHAR(30)   NOT NULL,
    SALARY     DECIMAL(9,2)  NOT NULL,
    LAST_UPDT  TIMESTAMP     NOT NULL DEFAULT CURRENT TIMESTAMP,
    PRIMARY KEY (EMP_ID)
) IN DSNDB04.TS_EMP;

-- 3. Create a unique index for the primary key.
CREATE UNIQUE INDEX IX_EMP_ID
       ON EMPLOYEE (EMP_ID ASC)
       USING STOGROUP SYSDEFLT
       PRIQTY 8000
       SECQTY 2000
       COPY NO;                        -- Image Copy can be temporarily disabled in the test environment.
