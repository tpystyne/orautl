-- Show Oracle SDU setting estimate

spool sdutest.log
set autotrace on statistics
set trimspool on
set pagesize 0
set termout off

set timing on
set arraysize 5000

column res noprint

select rpad(rownum, 1000, 'x') res from dba_objects where rownum <= 1000;

spool off
set autotrace off
set termout on
set pagesize 9999
set linesize 180

select event, 10*time_waited total_time, total_waits, 10*time_waited/total_waits avg_wait, 10*max_wait max_wait, round(1000000/total_waits) sdu_estimate
from v$session_event
where sid = sys_context('USERENV','SID')
and   event = 'SQL*Net more data to client';
