# Performance Update for 2,000,000 Records Batch Processing (Db2 for z/OS)

This is a document explaining Architectural upgrades applied to the COBOL `batch processing` program to safely and efficiently handle **2,000,000 (2 Million) records** targeting **Db2 for z/OS**.

---

## 🚀 Core Optimization Upgrades

### 1. Multi-Row Array Processing (Bulk MERGE)
*   1.The Problem:** The previous approach relied on row-by-row processing. Executing 2,000,000 individual SQL calls triggers massive context-switching overhead between the COBOL runtime and the Db2 database engine, leading to severe CPU consumption and prolonged execution times.
*   2.The Solution:** Implemented **Host Arrays** (`OCCURS 100 TIMES`) paired with the `FOR :ARRAY-IDX ROWS MERGE INTO` syntax. Data is buffered into memory and sent to Db2 in blocks of 100 records. This reduces individual SQL engine invocations by **99%**.

### 2. Scaled Intermittent COMMIT Strategy
*   1.The Problem:** Processing 2 million records under a single transaction will rapidly exhaust the **Db2 Active Log space (Log Full)**, resulting in a catastrophic transaction rollback. Additionally, maintaining uncommitted locks causes severe lock escalation and paralyzes concurrent system tasks.
*   2.The Solution:** The transaction boundaries have been recalibrated to issue an explicit `EXEC SQL COMMIT` precisely every **10,000 records**. This frequency releases row locks periodically and flushes the active transaction logs safely without causing operational overhead.

### 3. I/O Throughput Tuning via JCL
*   1.The Problem:** Reading 2 million sequential records from physical MVS storage via traditional access methods can cause severe physical I/O bottlenecks.
*   2.The Solution:** Configured the JCL stream to use sequential asynchronous pre-reading by appending the **`BUFNO=30`** parameter to the input DD statement (`//INFILE DD ...,BUFNO=30`). This instructs z/OS to allocate 30 virtual memory buffers, pre-loading data streams ahead of the COBOL execution pointer.

---

##  Performance Comparison

| Metric | Row-by-Row Execution (Old) | Multi-Row Bulk MERGE (Upgraded) |
| :--- | :--- | :--- |
| **SQL Invocations** | 2,000,000 calls | **20,000 calls** (100x reduction) |
| **COMMIT Frequency** | Every 5,000 records | **Every 10,000 records** |
| **Db2 Log Footprint** | High / Risk of Log Full | **Optimized & Stable** |
| **z/OS I/O Strategy** | Synchronous Single-Block | **Asynchronous Pre-buffered (`BUFNO=30`)** |

---

##  Summary of Code Adaptations
*  1torage Environment:** Tailored for **Fixed Blocked (FB) sequential datasets** with a standard Logical Record Length (**LRECL=100**).
*   2Methology used :** Utilizes native Db2 v12 **Upsert (MERGE)** functionality to dynamically evaluate whether to `INSERT` or `UPDATE` a record within a single atomic cycle.
*   3 Abend Handling:** Includes automated `ROLLBACK` commands and forces a clean mainframe system abend (`ILBOABN0`) if any batch or commit boundary fails, preventing data corruption.
