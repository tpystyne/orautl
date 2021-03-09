-- Show Oracle connection info

set pagesize 9999
set linesize 180

column inst_id format 999 heading INST
column sid format 99999
column serial# format 999999
column osuser format a16
column username format a25
column machine format a30 trunc
column program format a30 trunc
column client_driver format a16
column client_version format a12
column client_charset format a16
column encrypt format a8
column chksum format a8
column logon_time noprint

select distinct sci.inst_id, sci.sid, s.username, s.machine, sci.client_connection, sci.client_driver, sci.client_version, sci.client_charset,
  substr(encr.network_service_banner, 1, instr(encr.network_service_banner, ' Encryption service adapter')) encrypt,
  substr(chksum.network_service_banner, 1, instr(chksum.network_service_banner, ' Crypto-checksumming service adapter')) chksum,
program, logon_time
from gv$session_connect_info sci
join gv$session s on s.inst_id = sci.inst_id and s.sid = sci.sid
left join gv$session_connect_info encr on encr.inst_id = sci.inst_id and encr.sid = sci.sid
  and encr.network_service_banner like '% Encryption service adapter%'
left join gv$session_connect_info chksum on chksum.inst_id = sci.inst_id and chksum.sid = sci.sid
  and chksum.network_service_banner like '% Crypto-checksumming service adapter%'
order by username, machine, program;

column inst_id clear
column sid clear

