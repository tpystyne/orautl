# orautl

Oracle utility scripts for studying and diagnosing Oracle databases.

## Scripts

### `orastat.sql`

Comprehensive database diagnostic script. Covers:

- Instance info, uptime, version, and applied patches
- CDB/PDB containers, NLS character sets
- ASM disk groups and disks
- Control files, redo logs, standby logs, and data files
- Tablespace usage (data and temp)
- Data Guard configuration (archive destinations, protection mode, supplemental logging)
- RMAN configuration, backup status, and restore points
- Redo log volume history
- Non-default init parameters and LOGON triggers
- SGA/PGA memory, OS stats, and cluster interconnects
- System statistics, wait events, latch stats, and buffer waits
- Undo usage and history
- Segment sizes by owner, top 40 largest segments, and recyclebin
- Schema object inventory
- DBMS_SCHEDULER and legacy DBMS_JOB jobs
- Autotask operations
- Alert log: config entries, recent parameter changes, and recent errors

### `conninfo.sql`

Shows active session connection details from `gv$session_connect_info`: client driver, version, charset, and whether network encryption and checksumming are active.

### `dbtime.sql`

Queries AWR snapshots (`dba_hist_*`) for the last 7 days, computing per-interval deltas for DB time, DB CPU, background CPU, resource manager CPU waits, I/O waits, and OS load average.

### `sdutest.sql`

Estimates the effective SDU (Session Data Unit) size by fetching 1000 rows of 1 KB each with autotrace enabled, then checking `SQL*Net more data to client` wait stats to back-calculate the SDU in use.

## Required Privileges

The **`DBA` role** is sufficient for all scripts in typical single-instance or RAC database configurations. No `SYSDBA` is required.

The DBA role provides:

- `SELECT_CATALOG_ROLE` — for all `DBA_*` views
- `SELECT ANY DICTIONARY` — for `V$` / `GV$` dynamic performance views
- `EXECUTE on DBMS_QOPATCH` — for the OPatch inventory query in `orastat.sql` (granted to DBA in 12c+)
- Access to `SYS.AUX_STATS$` and `STMT_AUDIT_OPTION_MAP`

Notable exceptions:

| Object | Notes |
|---|---|
| `v$asm_diskgroup`, `v$asm_disk` | Accessible with DBA in most configs; in a dedicated ASM instance may require `SYSASM` |
| `dba_hist_*` views (`dbtime.sql`, parts of `orastat.sql`) | Require the **Oracle Diagnostics Pack** license in addition to DBA |
| `ALTER SESSION` | Granted to all users by default via PUBLIC |
