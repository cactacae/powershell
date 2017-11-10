#RDSessionTools

RDSessionTools provie a friendly PowerShell wrapper around the quser and logoff commands.
Get-RDSession converts Active and Idle session times into a TimeSpan object.
Remove-RDSession accepts a ComputerName and SessionID parameter to log a usedr off remotely.
Conveniently the SessionID parameter is aliased to ID, allowing the results of Get-RDSession to be piped in.

##Examples:
```powershell
Get-RDSession fileserver.domain.com | Where {$_.State -eq 'Disc'} | Remove-RDSession
Will Log Off all Disconnected sessions

```powershell
Remove-RDSession fileserver.domain.com 3
Will log off session 3 on fileserver

```powershell
Get-AdComputer -Filter 'Name -like "SQL*"' | Get-RDSession
Get RD Sessions for all domain computers with a name starting with SQL
