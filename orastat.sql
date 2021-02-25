-- Show Oracle database configuration and statistics
--
set echo on
set tab off
set trimspool on
set pagesize 9999
set linesize 180
set verify off
set timing off
break on report

alter session set nls_date_format = 'YYYY.MM.DD HH24:MI:SS';
select sysdate from dual;

rem show instance startup time
column inst_id format 999 heading INST
column instance_name format a13
column host_name format a40
column status format a12
select inst_id, instance_name || decode(sys_context('USERENV', 'INSTANCE_NAME'), instance_name, '*', '') instance_name,
       host_name, status,  
       startup_time,
       trunc(sysdate - startup_time,2) days_up
from gv$instance order by inst_id;

rem show database info
select dbid, name, created, controlfile_created, resetlogs_change#, resetlogs_time from v$database;
select con_id, creation_time from v$datafile where ts# = 1 order by con_id;

column con_id format 9999
column name format a12
column total_gb format 99999.99
select con_id, name, dbid, create_scn, to_char(open_time,'YYYY.MM.DD HH24:MI:SS') open_time, open_mode, total_size/1024/1024/1024 total_gb, recovery_status
from v$containers order by con_id;
column name clear

column parameter format a25
column value format a80
select parameter, value from v$nls_parameters where parameter like 'NLS%CHARACTERSET';

column global_name format a80
select global_name from global_name;

column group_number heading GROUP# format 9999
column disk_number heading DISK# format 9999
column total_gb format 999,999
column free_gb format 999,999
column usable_file_gb format 999,999
column path format a50
column state format a11
select group_number, name,
       total_mb/decode(type,'HIGH',3,'NORMAL',2,1)/1024 total_gb, 
       free_mb/decode(type,'HIGH',3,'NORMAL',2,1)/1024 free_gb, 
       usable_file_mb/1024 usable_file_gb,
       type, state 
from v$asm_diskgroup order by group_number;

select group_number, disk_number, name, state, mode_status, total_mb/1024 total_gb, free_mb/1024 free_gb, failgroup
from v$asm_disk order by group_number, disk_number;

compute sum of gbytes on report
compute sum of gmaxbytes on report
column con_id noprint
column thread# format 999999
column group# format 99999
column file_id format 9999 heading FILE#
column type format a7
column status format a10
column name format a96
column gbytes format 999,999.999
column incrgbytes format 999.999999
column maxgbytes format 999,999

select * from v$controlfile;
select l.thread#, f.group#, f.member name, l.bytes/1024/1024/1024 gbytes, f.type, l.status, l.sequence#
from v$log l, v$logfile f
where l.group# = f.group#
order by l.thread#, f.group#, f.member;
select l.thread#, f.group#, f.member name, l.bytes/1024/1024/1024 gbytes, f.type, l.status, l.sequence#
from v$standby_log l, v$logfile f
where l.group# = f.group#
order by l.thread#, f.group#, f.member;

select file_id, file_name name, bytes/1024/1024/1024 gbytes, increment_by*(bytes/blocks/1024/1024/1024) incrgbytes, maxbytes/1024/1024/1024 maxgbytes 
from dba_data_files
order by tablespace_name, relative_fno;
select file_id, file_name name, bytes/1024/1024/1024 gbytes, increment_by*(bytes/blocks/1024/1024/1024) incrgbytes, maxbytes/1024/1024/1024 maxgbytes  
from dba_temp_files
order by tablespace_name, relative_fno;

compute sum of used_gb on report
compute sum of alloc_gb on report
compute sum of max_gb on report
column tablespace_name format a30
column bigfile format a3
column extent_management format a10
column allocation_type format a9
column segment_space_management format a6
column blksize format 99999
column logging format a9
column used_gb format 99999.999
column alloc_gb format 99999.999
column max_gb format 99999.999
column status format a9
column contents noprint

select tablespace_name, contents, bigfile, extent_management, allocation_type, min_extlen, segment_space_management, block_size blksize,
       decode(force_logging, 'YES', 'FORCE', logging) logging,
       (select round(sum(bytes)/1024/1024/1024,3) from dba_segments where tablespace_name = ts.tablespace_name) used_gb,
       (select round(sum(bytes)/1024/1024/1024,3) from dba_data_files where tablespace_name = ts.tablespace_name) alloc_gb,
       (select round(sum(greatest(bytes,maxbytes))/1024/1024/1024,3) from dba_data_files where tablespace_name = ts.tablespace_name) max_gb,
       status
from dba_tablespaces ts
where contents != 'TEMPORARY'
union all
select tablespace_name, contents, bigfile, extent_management, allocation_type, min_extlen, segment_space_management, block_size blksize,
       decode(force_logging, 'YES', 'FORCE', logging) logging,
       (select round(sum(bytes_used)/1024/1024/1024,3) from v$temp_extent_pool where tablespace_name = ts.tablespace_name) used_gb,
       (select round(sum(bytes)/1024/1024/1024,3) from dba_temp_files where tablespace_name = ts.tablespace_name) alloc_gb,
       (select round(sum(greatest(bytes,maxbytes))/1024/1024/1024,3) from dba_temp_files where tablespace_name = ts.tablespace_name) max_gb,
       status
from dba_tablespaces ts
where contents = 'TEMPORARY'
order by contents, tablespace_name;

column contents clear
column status clear

column database_role format a16
column log_mode format a12
column protection_mode format a20
column protection_level format a20
column force_logging format a5
column suppl_min format a9
column suppl_pk format a8
column suppl_ui format a8
column suppl_fk format a8
column suppl_all format a9
column flashback_on format a5

select database_role, log_mode, protection_mode, protection_level, force_logging, 
       supplemental_log_data_min suppl_min, supplemental_log_data_pk suppl_pk, supplemental_log_data_ui suppl_ui,
       supplemental_log_data_fk suppl_fk, supplemental_log_data_all suppl_all,
       flashback_on
from v$database;

column enabled format a8
select thread#, status, enabled, last_redo_sequence#, last_redo_block, last_redo_change#, last_redo_time from v$thread;

column destination format a30
column type format a8
column status format a30 trunc
column synchronization_status format a22
column recovery_mode format a30

select destination, type, 
  nvl(error,status) status,
  synchronization_status, synchronized, recovery_mode
from v$archive_dest_status 
where destination is not null;

column type format a28
column total_size format 999,999,999
select type, records_used, records_total, record_size, records_total*record_size total_size  from v$controlfile_record_section;
column type clear

column name format a50
column file_type format a20
column space_limit_gb format 999,999.999
column space_used_gb format 99,999.999
column space_reclaimable_gb format 99,999.999
select name, space_limit/1024/1024/1024 space_limit_gb, space_used/1024/1024/1024 space_used_gb, space_reclaimable/1024/1024/1024 space_reclaimable_gb,
       number_of_files
from v$recovery_file_dest;
select * from v$flash_recovery_area_usage;

select * from v$flashback_database_log;
select * from v$restore_point order by scn;

column name format a50
column value format a80
select name, value from v$rman_configuration order by name, value;

compute min of checkpoint_change# on report
compute min of checkpoint_time on report
compute max of completion_time on report
compute max of absolute_fuzzy_change# on report
compute sum of blocks on report
column checkpoint_time format a19
column completion_time format a19
column creation_change# heading CREATION_SCN format 999999999999
column incremental_change# heading INCREMENTAL_SCN format 999999999999
column checkpoint_change# heading CHECKPOINT_SCN format 999999999999
column absolute_fuzzy_change# heading FUZZY_SCN format 999999999999
column blocks format 999,999,999

select bdf.file#, bdf.creation_change#, bdf.incremental_change#, bdf.checkpoint_change#, 
       to_char(bdf.checkpoint_time) checkpoint_time, to_char(bdf.completion_time) completion_time, absolute_fuzzy_change#, bdf.blocks
from v$backup_datafile bdf 
where bdf.checkpoint_change# =
  (select max(bdf2.checkpoint_change#) 
   from v$backup_datafile bdf2
   where bdf2.file# = bdf.file# and bdf2.creation_change# = bdf.creation_change#
   and   bdf2.incremental_change# <= bdf2.creation_change#)
and   bdf.creation_change# = 
  (select max(df.creation_change#) 
   from v$datafile df
   where df.file# = bdf.file#)
order by bdf.file#;

column name format a30
column unrecoverable_change# format 99999999999999
select df.file#, df.ts#, ts.name, df.unrecoverable_time, df.unrecoverable_change# 
from v$datafile df
join v$tablespace ts on ts.ts# = df.ts#
where unrecoverable_change# > 0
order by ts.name, df.unrecoverable_change#;

column corruption_change# format 99999999999999
select * from v$database_block_corruption
order by corruption_change#;

column filename format a45
select * from v$block_change_tracking;

compute max of logs on report
compute max of gbytes on report
compute max of gbytes_in_24h on report
compute max of gbytes_in_7days on report
compute max of max_mbytes_per_sec on report
column gbytes format 9999.999
column gbytes_in_24h format 99999.999
column gbytes_in_7days format 999999.999
column max_mbytes_per_sec format 999.999

select next_time, logs, mbytes/1024 gbytes,
       sum(mbytes/1024) over (order by next_time range 1 preceding) gbytes_in_24h,
       sum(mbytes/1024) over (order by next_time range 7 preceding) gbytes_in_7days,
       max_mbytes_per_sec
from (select trunc(next_time, 'HH24') next_time, count(*) logs, sum(mbytes) mbytes, max(mbytes_per_sec) max_mbytes_per_sec
      from (select distinct thread#, sequence#, next_time,
                   blocks*block_size/1024/1024 mbytes, 
                   blocks*block_size/1024/1024/decode(next_time - first_time, 0, null, next_time - first_time)/24/60/60 mbytes_per_sec 
      from v$archived_log) al
      group by trunc(next_time, 'HH24'))
order by next_time
/

select trunc(first_time, 'HH24') first_time, count(*) logs 
from v$log_history lh
where not exists (select null from v$archived_log)
group by trunc(first_time, 'HH24')
order by trunc(first_time, 'HH24');


rem show version information
column platform_name format a80
column version format a12
select platform_name from v$database;
select banner from v$version;

with lsinv as (select dbms_qopatch.get_opatch_lsinventory patch_output from dual)
select res.*
  from lsinv,
       xmltable('InventoryInstance/patches/*'
          passing lsinv.patch_output
          columns
             patch_id number path 'patchID',
             patch_uid number path 'uniquePatchID',
             description varchar2(80) path 'patchDescription',
             applied_date varchar2(30) path 'appliedDate',
             sql_patch varchar2(8) path 'sqlPatch',
             rollbackable varchar2(8) path 'rollbackable'
       ) res
order by applied_date;

column action format a20
column version format a12
column comments format a50
column bundle_series format a16
column action_time format a30
select action, version, comments, action_time 
from dba_registry_history order by action_time;

column version format a12
column description format a70
column action format a8
column status format a12
column action_time format a19

select patch_id, patch_uid, description, action, status, to_char(action_time, 'YYYY-MM-DD HH24:MI:SS') action_time
from dba_registry_sqlpatch order by action_time;

column parameter format a40
column value format a40
column comp_id format a10
column comp_name format a40
select * from v$option order by value, parameter;
select comp_id, comp_name, version, status from dba_registry order by comp_id;

rem show non-default system parameters
column con format 99
column name format a35
column display_value format a75

select display_value from v$parameter where name = 'spfile';

select con_id con, name, display_value
from  v$system_parameter2 where isdefault = 'FALSE' or ismodified = 'MODIFIED'
order by name, con_id, ordinal;

set long 4096
set longchunksize 256
column trigger_name format a30
select trigger_name, trigger_body from dba_triggers where triggering_event like 'LOGON%';
set long 80
set longchunksize 80

select pname, pval1
from sys.aux_stats$
where sname = 'SYSSTATS_MAIN';

column start_time format a30
select start_time, max_iops, max_mbps, max_pmbps, latency, num_physical_disks from dba_rsrc_io_calibrate;

column operation_name format a40
select operation_name, to_number(manual_value) manual, to_number(calibration_value) calibration, to_number(default_value) default_ 
from v$optimizer_processing_rate order by 1;

select count(*), count(last_analyzed), min(last_analyzed), max(last_analyzed) 
from dba_tab_statistics where object_type = 'FIXED TABLE';

column property_name format a30
column property_value format a50
select property_name, property_value from database_properties order by property_name;

column limit_value format a12
select resource_name name, max_utilization, limit_value
from v$resource_limit
where limit_value not like '%UNLIMITED%' and limit_value not like '% 0'
order by max_utilization/to_number(limit_value) desc;

rem show sga information
select name, round(bytes/1024/1024) mbytes, resizeable from v$sgainfo;
select pool, name, round(bytes/1024/1024) mbytes from v$sgastat
where bytes > 1024*1024
order by bytes desc;

column oper_type format a15
select oper_type, parameter, initial_size/1024/1024 initial_mb, final_size/1024/1024 final_mb, end_time
from v$sga_resize_ops;
--order by end_time, oper_type desc;

column stat_name format a64
column value format 99,999,999,999,999
select * from v$pgastat
where value > 0;

select stat_name, value from v$osstat order by stat_name;

select * from gv$cluster_interconnects;

rem show system statistics since instance startup
column name format a60
column value format 999,999,999,999,999
select name, value from v$sysstat 
where value > 0
order by upper(name);

column name format a40
column network_name format a40
column failover_method format a20
column failover_type format a20
column failover_retries heading RETRIES
column failover_delay heading DELAY
select name, network_name, failover_method, failover_type, failover_retries, failover_delay
from dba_services order by name;

select inst_id, name, blocked from gv$active_services order by name, inst_id;

column service_name format a20
select service_name, inst_id,
  round(sum(decode(stat_name, 'DB CPU', value, null))/1000000) cpu,
  round(sum(decode(stat_name, 'DB time', value, null))/1000000) ela,
  round(sum(decode(stat_name, 'sql execute elapsed time', value, null))/1000000) exec,
  round(sum(decode(stat_name, 'parse time elapsed', value, null))/1000000) prs,
  round(sum(decode(stat_name, 'user I/O wait time', value, null))/1000000) io,
  round(sum(decode(stat_name, 'application wait time', value, null))/1000000) app,
  round(sum(decode(stat_name, 'concurrency wait time', value, null))/1000000) conc,
  round(sum(decode(stat_name, 'cluster wait time', value, null))/1000000) clu
from gv$service_stats
where service_name not like 'SYS.KUPC$S%'
group by service_name, inst_id
order by service_name, inst_id;

rem show statistics of current sessions
set numwidth 8
column inst_id heading INST format 99
column sid format 9999
column username format a20
column program format a30 trunc
column machine format a12 trunc
column opencur format 9999
column execs format 9999999
column days format 999.99
compute sum of execs on report
compute sum of logios on report
compute sum of phyios on report
compute sum of calls on report
compute sum of cpu on report
compute sum of trips on report
compute sum of bytesout on report
compute sum of bytesin on report
compute sum of commits on report
compute sum of sesmem on report
compute sum of procmem on report
compute sum of redosize on report

set termout on
select s.inst_id, s.sid, 
       s.username,
       sum(decode(n.name, 'execute count', value, null)) execs,
       sum(decode(n.name, 'SQL*Net roundtrips to/from client', value, null)) trips,
       sum(decode(n.name, 'user commits', value, null)) commits,
       sum(decode(n.name, 'CPU used by this session', value, null)) cpu,
       sum(decode(n.name, 'consistent gets', value, 'consistent changes', value, 'db block changes', value, null)) logios,
       sum(decode(n.name, 'physical reads', value, 'physical writes', value, 'redo writes', value, null)) phyios,
       sum(decode(n.name, 'redo size', value, null)) redosize,
       sum(decode(n.name, 'session uga memory', value, null)) sesmem,
       sysdate - s.logon_time days, s.program
from gv$sesstat st
join v$statname n on n.statistic# = st.statistic# 
join gv$session s on st.inst_id = s.inst_id and st.sid = s.sid 
where n.name in ('execute count', 'SQL*Net roundtrips to/from client','user commits','CPU used by this session',
                 'consistent gets','consistent changes','db block changes','physical reads','physical writes','redo writes',
                 'redo size','session uga memory')  
group by s.inst_id, s.sid, s.username, s.machine, s.program, s.logon_time, s.process
order by s.logon_time, s.process;


select target_mttr, estimated_mttr, recovery_estimated_ios, actual_redo_blks from v$instance_recovery;

clear computes
set numwidth 10
rem show io statistics
select sum(phyrds) phyrds, sum(phyblkrd) phyblkrd,
       sum(phyblkrd)/sum(phyrds) avg_blks_per_read, 10*sum(readtim)/sum(phyrds) msecs_per_read
from v$filestat;

rem show datafile io statistics
compute sum of phyrds on report
compute sum of singleblkrds on report
compute sum of phyblkrd on report
compute sum of phywrts on report
compute sum of phyblkwrt on report
column file# format 9999
column avgrtime format 999.99
select df.tablespace_name, file#, singleblkrds, phyrds, phyblkrd, 10*readtim/phyrds avgrtime, phywrts, phyblkwrt
from v$filestat fs, dba_data_files df
where fs.file# = df.file_id
order by df.tablespace_name, file#;

rem show dnfs statistics
column svrname format a16
column dirname format a60
select svrname, dirname from v$dnfs_servers;

column filename format a60
select * from v$dnfs_files order by pnum, filename;

select pnum, nfs_lookup, nfs_read, nfs_write 
from v$dnfs_stats
where nfs_read > 0 or nfs_write > 0
order by pnum;


column phyblkrd new_value phyblkrd format 999,999,999,999
select value phyblkrd from v$sysstat where name = 'physical reads';

column owner format a30
column object_name format a30
column subobject_name format a30
column statistic_name format a25

select owner, object_name, subobject_name, statistic_name, value from v$segment_statistics
where statistic_name like 'physical%'
and value > to_number('&phyblkrd')/100
order by value;

column logblkrd new_value logblkrd format 9,999,999,999,999
select value logblkrd from v$sysstat where name = 'consistent gets';

select owner, object_name, subobject_name, statistic_name, value from v$segment_statistics
where statistic_name like 'logical%'
and value > to_number('&logblkrd')/100
order by value;


rem show statements that have elapsed time over 15 minutes
column execs format 99,999,999
column disk_reads format 999,999,999
column buffer_gets format 9,999,999,999
column rows_ format 999,999,999
column sorts format 999,999
column elapsed_time format 999,999,999,999
column cpu_time format 99,999,999,999
column userid format 99999
select executions execs, disk_reads, buffer_gets, rows_processed rows_, sorts,
       elapsed_time, cpu_time, sql_id, sql_text
from v$sqlstats
where elapsed_time > 900000000
order by elapsed_time desc;

set timing on
declare
  cnt number;
begin
  for i in 1..10000 loop
    select /*+ index(saom i_stmt_audit_option_map) */  sum(property) into cnt from stmt_audit_option_map saom where option# = 3;
  end loop;
end;
/
set timing off

select executions execs, rows_processed, elapsed_time, cpu_time, disk_reads, buffer_gets, sql_text from v$sqlstats where sql_id = 'duv7z02u6x7n5';
select executions execs, rows_processed, elapsed_time, cpu_time, disk_reads, buffer_gets, sql_text from v$sqlstats where sql_id = 'aspkyv3bzjpw0';

select stat_name, value from v$sys_time_model;

rem show system event wait statistics
column event format a60
column total_time_ms format 999999,999,999
column avg_wait_ms format 999999,999.9
column wait_class format a16
select event, 10*time_waited total_time_ms, total_waits, 10*average_wait avg_wait_ms, wait_class
from v$system_event
where time_waited > 0
order by decode(wait_class, 'Idle', 1, 0), time_waited desc;

break on event skip 0 
select event, wait_time_milli, wait_count from v$event_histogram
where wait_count > 0
order by upper(event), wait_time_milli;

rem show latch get statistics
column name format a40
select name, gets, misses, sleeps, immediate_gets igets, immediate_misses imisses
from v$latch
where misses + immediate_misses > 0
order by misses + immediate_misses desc;

rem show buffer waits
select * from v$waitstat
where count > 0;

select tablespace_name, retention from dba_tablespaces
where contents = 'UNDO'
order by tablespace_name;

rem show rollback segment statistics
compute sum of rssize on report
select usn, xacts, waits, gets, writes, wraps, rssize, status
from v$rollstat;

break on report
compute max of undoblks on report
compute max of mbytes_1h on report
compute max of mbytes_24h on report
compute max of retention on report
compute max of maxquerylen on report
column mbytes_1h format 999,999
column mbytes_24h format 9,999,999

select begin_time, end_time, txncount, undoblks, 
  sum(undoblks*block_size/1024/1024) over (order by begin_time range 1/24 preceding) mbytes_1h,
  sum(undoblks*block_size/1024/1024) over (order by begin_time range 1 preceding) mbytes_24h,
  tuned_undoretention retention, maxquerylen, maxqueryid
from v$undostat
join v$datafile on file# = 1
order by begin_time;

column gbytes format 99,999.999

def ORACLE_ADMIN_USERS="'ANONYMOUS','CTXSYS','DBSNMP','EXFSYS','LBACSYS','MDSYS','MGMT_VIEW','OLAPSYS','OWBSYS','ORDPLUGINS','ORDSYS','OUTLN','SI_INFORMTN_SCHEMA','SYS','SYSMAN','SYSTEM','TSMSYS','WK_TEST','WKSYS','WKPROXY','WMSYS','XDB'"
def ORACLE_NONADM_USERS="'APEX_030200','APEX_040000','APEX_PUBLIC_USER','APPQOSSYS','DIP','CSMIG','FLOWS_030000','FLOWS_FILES','MDDATA','ORACLE_OCM','ORDDATA','OWBSYS_AUDIT','PERFSTAT','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','XS$NULL'"
def ORACLE_DEMO_USERS="'BI','HR','OE','PM','IX','SH','SCOTT'"
def ORACLE_OBS_USERS="'AURORA$JIS$UTILITY$','AURORA$ORB$UNAUTHENTICATED','OSE$HTTP$ADMIN','DMSYS','ODM','ODM_MTR'"

select owner, count(*) segments, sum(extents) extents, sum(bytes)/1024/1024/1024 gbytes
from dba_segments
where owner in (&ORACLE_ADMIN_USERS,&ORACLE_NONADM_USERS,&ORACLE_DEMO_USERS,&ORACLE_OBS_USERS)
group by owner
order by owner;

select owner, count(*) segments, sum(extents) extents, sum(bytes)/1024/1024/1024 gbytes
from dba_segments
where owner not in (&ORACLE_ADMIN_USERS,&ORACLE_NONADM_USERS,&ORACLE_DEMO_USERS,&ORACLE_OBS_USERS)
group by owner
order by owner;

column segment_name format a30
column partition_name format a30
column segment_type format a18
select * from (
  select owner, segment_name, partition_name, segment_type, bytes/1024/1024/1024 gbytes
  from dba_segments
  order by bytes desc, owner, segment_name, partition_name)
where rownum <= 40;

select owner, count(*) segments, sum(ts.block_size * rbin.space)/1024/1024/1024 gbytes 
from dba_recyclebin rbin
join dba_tablespaces ts on ts.tablespace_name = rbin.ts_name
group by owner
order by owner;

column object_type format a19
select owner, object_type, count(*), to_char(max(last_ddl_time), 'YYYY.MM.DD HH24:MI:SS') last_ddl_time
from dba_objects
where owner not in (&ORACLE_ADMIN_USERS,&ORACLE_NONADM_USERS,&ORACLE_DEMO_USERS,&ORACLE_OBS_USERS)
group by cube(owner, object_type)
order by owner, object_type;

column job format 9999
column log_user format a12
column what format a60
column interval format a48

select job, log_user, what, interval, broken from dba_jobs order by log_user, what;

column job_name format a30
column repeat_interval format a75

select owner, job_name, repeat_interval, enabled from dba_scheduler_jobs order by owner, job_name;

column operation_name format a40
column client_name format a40
column window_name format a20
column status format a12
column last_good_date format a40
column start_time format a40
column duration format a15
select operation_name, status from dba_autotask_operation order by operation_name;
select client_name, to_char(job_start_time, 'Dy YYYY.MM.DD HH24:MI:SS') start_time, job_duration duration, job_status status
from dba_autotask_job_history order by job_start_time;
select window_name, start_time, duration from dba_autotask_schedule order by start_time;

column originating_timestamp format a21
column message_text format a148

column adr_home new_value adr_home
select 'diag/rdbms/' || lower(value) adr_home  from v$parameter where name = 'db_unique_name';

rem show configuration from alert log
select originating_timestamp, message_text from (
  select record_id,
         to_char(originating_timestamp, 'YYYY-MM-DD HH24:MI:SS') originating_timestamp, 
         message_text ,
         row_number() over (partition by substr(message_text, 1, 20) order by record_id desc) lastn
  from v$diag_alert_ext      
  where adr_home like '&ADR_HOME/%'
  and   (message_text like 'Large Page%' or
         message_text like '  PAGESIZE%' or
         message_text like '     2048K%' or
         message_text like 'cluster interconnect IPC%' or
         message_text like 'Oracle instance running with ODM%' or
         message_text like 'ORACLE_HOME%' or
         message_text like 'System name:%' or
         message_text like 'Node name:%' or
         message_text like 'Release:%' or
         message_text like 'Version:%' or
         message_text like 'Machine:%' or
         message_text like 'VM name:%')
  )
where lastn <= 1
order by record_id;

rem show last parameter changes from alert log
select originating_timestamp, message_text from (
  select record_id,
         to_char(originating_timestamp, 'YYYY-MM-DD HH24:MI:SS') originating_timestamp,
         message_text ,
         row_number() over (partition by substr(message_text, 1, 240) order by record_id desc) lastn
  from v$diag_alert_ext
  where adr_home like '&ADR_HOME/%'
  and   (upper(message_text) like 'ALTER SYSTEM SET%' or
         upper(message_text) like 'ALTER SYSTEM RESET%'
         )
  )
where lastn <= 3
order by record_id;

rem show last error messages from alert log
select originating_timestamp, message_text from (
  select record_id,
         to_char(originating_timestamp, 'YYYY-MM-DD HH24:MI:SS') originating_timestamp, 
         message_text ,
         row_number() over (partition by substr(message_text, 1, 9) order by record_id desc) lastn
  from v$diag_alert_ext      
  where adr_home like '&ADR_HOME/%'
  and   (message_level < 8 or
         message_text like 'ORA-%')
  )
where lastn <= 5
order by record_id;

column con_id clear
clear breaks
clear computes
