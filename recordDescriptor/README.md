# Mainframe Batch Data Ingestion System: COBOL Dataset to DB2

This document provides a technical overview of the production batch data ingestion framework developed to process massive flat files into IBM DB2 for z/OS. 

---

## 🛠️ System Overview & Architecture

The ingestion system consists of a permanent, compiled **COBOL-DB2 Batch Application** executing within the native **z/OS (MVS)** or **UNIX System Services (USS)** environments. It is orchestrated via Job Control Language (JCL) utilizing the **IKJEFT01** TSO Terminal Monitor Program.

The architecture is designed to handle exceptionally large datasets with robust error isolation, data type mapping, and precise transaction management.

### Data Flow Diagram
```
[ Large Inbound Dataset ] 
  (LRECL = 2,000,000)
         │
         ▼
 ┌───────────────┐
 │ COBOL Program │ ──(Invalid Records)──► [ Error Log File (ERRFILE) ]
 └───────────────┘                          (No Process Interruption)
         │
  (Validated Data)
         │
         ▼
 ┌───────────────┐
 │  DB2 Engine   │
 └───────────────┘
```

---

## 🗄️ DB2 Target Environment & Capabilities

The target environment is hosted on an enterprise **IBM DB2 for z/OS** subsystem configured to support large-scale, high-conformance data types.

### Database Schema Structure
The data architecture maps large-capacity alphanumeric variables down to standard columns while allowing optional indicators to prevent runtime parsing faults:

* **ID (`VARCHAR(100)`)**: Unique identifier configured as a character array to handle highly precise, multi-character alphanumeric alphanumeric structures.
* **EMPLOYEE_NAME (`VARCHAR(200)`)**: High-capacity character variable supporting long name lengths.
* **WAGE (`VARCHAR(100)`)**: Handled as an explicit variable string to preserve infinite-precision financial metrics without IEEE double truncation risks.
* **STREET (`VARCHAR(100) - NULLABLE`)**: Variable address block. Supports active **Null Indicators**.
* **TELEPHONE (`VARCHAR(100) - NULLABLE`)**: Variable alphanumeric layout to capture long international numbers and extensions. Supports active **Null Indicators**.

### Enterprise Capabilities Enabled

#### 1. Dynamic Null Pointer Handling
The database explicitly supports `NULL` data states for the `STREET` and `TELEPHONE` attributes. Rather than inserting empty white space, the program leverages **Level-49 Null Indicator Variables** (`PIC S9(4) COMP`).
* A prefix value of `-1` instructs the engine to assign a native database `NULL`.
* A prefix value of `0` instructs the engine to process the accompanied host variable text cleanly.

#### 2. Segmented Transaction Log Protection (Intermittent COMMIT)
To maintain optimal memory consumption on the active DB2 logging space, the application implements an **Intermittent Commit Strategy**.
* The program keeps an internal tracking register of successful rows processed.
* A mathematical evaluation triggers a `COMMIT` command precisely every **5,000 records**.
* This approach prevents **DB2 Lock Escalation** from Row-Level locks to exclusive Table-Level locks, maximizing concurrently processing jobs.

#### 3. Fault-Tolerant Record Processing (Isolating Errors)
Instead of forcing a catastrophic job termination via an **S0C7 data exception** or **SQL error abend**, bad rows are isolated. Non-numeric or blank records are captured, formatted with structural diagnostic logs, and streamed into a separate **Error Log File (`ERRFILE`)**, while the main iteration loop seamlessly proceeds to the next sequence.

---

## 📂 System File Layout Constraints

The input/output subsystems interact with files that use extensive buffer limits:
* **LRECL Configuration**: Set explicitly to **2,000,000 bytes** to allow for comprehensive analytical extractions.
* **RECFM**: Fixed-Block (`FB`) mapping ensures rapid byte tracking across the storage blocks.

---
*Disclaimer: This documentation is generated for technical implementation reference across architectural review boards.*
