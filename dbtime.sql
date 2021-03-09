-- Show Oracle AWR statistics over time

set pagesize 9999
set linesize 150

set tab off
column inst format 999
column end_interval_time format a20
column roundtrips format 999,999,999
column dbtime format 99999.99
column dbcpu format 99999.99
column bgcpu format 99999.99
column resmgr format 99999.99
column iowait format 99999.99
column avgload format 999.99

select
    snap.instance_number inst, snap.snap_id, to_char(snap.end_interval_time, 'Dy YYYY.MM.DD HH24:MI') end_interval_time,
    roundtrips.value - lag(roundtrips.value) over (partition by snap.instance_number order by snap.instance_number, snap.snap_id) roundtrips,
    dbtime.value/1000000 - lag(dbtime.value/1000000) over (partition by snap.instance_number order by snap.instance_number, snap.snap_id) dbtime,
    dbcpu.value/1000000 - lag(dbcpu.value/1000000) over (partition by snap.instance_number order by snap.instance_number, snap.snap_id) dbcpu,
    bgcpu.value/1000000 - lag(bgcpu.value/1000000) over (partition by snap.instance_number order by snap.instance_number, snap.snap_id) bgcpu,
    resmgr.time_waited_micro/1000000 - lag(resmgr.time_waited_micro/1000000) over (partition by snap.instance_number order by snap.instance_number, snap.snap_id) resmgr,
    iowait.time_waited_micro/1000000 - lag(iowait.time_waited_micro/1000000) over (partition by snap.instance_number order by snap.instance_number, snap.snap_id) iowait,
    avgload.value/1 avgload
from dba_hist_snapshot snap
join dba_hist_sysstat roundtrips on snap.snap_id = roundtrips.snap_id and snap.instance_number = roundtrips.instance_number and roundtrips.stat_name = 'SQL*Net roundtrips to/from client'
join dba_hist_sys_time_model dbtime on snap.snap_id = dbtime.snap_id and snap.instance_number = dbtime.instance_number and dbtime.stat_name = 'DB time'
join dba_hist_sys_time_model dbcpu on dbcpu.snap_id = snap.snap_id and dbcpu.instance_number = snap.instance_number and dbcpu.stat_name = 'DB CPU'
join dba_hist_sys_time_model bgcpu on bgcpu.snap_id = snap.snap_id and bgcpu.instance_number = snap.instance_number and bgcpu.stat_name = 'background cpu time'
join dba_hist_system_event iowait on iowait.snap_id = snap.snap_id and iowait.instance_number = snap.instance_number and iowait.event_name in ('db file sequential read','cell single block physical read')
left join dba_hist_system_event resmgr on resmgr.snap_id = snap.snap_id and resmgr.instance_number = snap.instance_number and resmgr.event_name = 'resmgr:cpu quantum'
join dba_hist_osstat avgload on avgload.snap_id = snap.snap_id and avgload.instance_number = snap.instance_number and avgload.stat_name = 'LOAD'
where snap.end_interval_time > sysdate - 7
order by inst, snap_id;
