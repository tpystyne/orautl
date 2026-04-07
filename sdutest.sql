-- Show Oracle SDU setting estimate

spool sdutest.log
set autotrace on statistics
set trimspool on
set pagesize 0
set termout off

set arraysize 5000

column res noprint

select rpad(rownum, 4000, 'x') res from dba_objects where rownum <= 2500;

spool off
set autotrace off
set termout on
set pagesize 9999
set linesize 180

column event format a30
column avg_wait_ms format 99.99

select event, 10*time_waited/total_waits avg_wait_ms, total_waits,  round(10000000/(total_waits+1)) sdu_estimate
from v$session_event
where sid = sys_context('USERENV','SID')
and   event = 'SQL*Net more data to client';

