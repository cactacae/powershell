# RDSessionTools

RDSessionTools provide a friendly PowerShell wrapper around the quser and logoff commands.

Get-RDSession converts Idle session times into a TimeSpan object.

Remove-RDSession accepts a ComputerName and SessionID parameter to log a usedr off remotely.

SessionID parameter is aliased to ID, allowing the results of Get-RDSession to be piped in.


## Examples:

### Log Off all Disconnected sessions
```powershell
Get-RDSession fileserver.domain.com | Where {$_.State -eq 'Disc'} | Remove-RDSession

### Log off session 3 on fileserver
```powershell
Remove-RDSession fileserver.domain.com 3

### Get RD Sessions for all domain computers with a name starting with SQL
```powershell
Get-AdComputer -Filter 'Name -like "SQL*"' | Get-RDSession
