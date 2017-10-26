# Author: Walter Williams
# 3/31/2015

# Retrieve enabled users who have not logged in for 45 days and users who have never logged in

# Either pass a pscredntials object in as a paramter or you will be prompted for credentials
# If no server is specified then the InfrastructureMaster for the local machines domain will be used

# Examples:

# Export list of inactive users to csv
# Get-InactiveUsers.ps1 | Export-CSV Inactive.csv
#
# Retrive list of inactive users for MYDOMAIN domain and format to table
# Get-InactiveUsers.ps1 -server dc2.mydomain.com | ft
#
# Disable current inactive users, but use -WhatIf flag so that no changes are actually made
# Get-InactiveUser.ps1 | % {set-aduser $_.SamAccountName -Enabled $false -WhatIf}

# 



param (
    [Parameter(Mandatory=$False,Position=1)]
    [string]$OutputFile,

    [Parameter(Mandatory=$False,Position=2)]
    [int]$DaysInactive = 45,

    [Parameter(Mandatory=$False,Position=3)]
    [string]$GroupExclude = "GG.POL.DoNotDisable",

    [Parameter(Mandatory=$False,Position=4)]
    [string]$Server,

    [Parameter(Mandatory=$False,Position=5)]
    [PSCredential]$Credential

)


#Author:    	Glenn Sizemore glnsize@get-admin.com
#
#Purpose:	Convert a DN to a Canonical name, and back again.
#
#Example:	PS > ConvertFrom-Canonical 'get-admin.local/test/test1/Sizemore, Glenn E'
#		CN=Sizemore\, Glenn E,OU=test1,OU=test,DC=getadmin,DC=local
#	 	PS > ConvertFrom-DN 'CN=Sizemore\, Glenn E,OU=test1,OU=test,DC=getadmin,DC=local'
#		get-admin.local/test/test1/Sizemore, Glenn E
# Mod by Tilo 2014-04-01 
function ConvertFrom-DN 
{
param([string]$DN=(Throw '$DN is required!'))
    foreach ( $item in ($DN.replace('\,','~').split(",")))
    {
        switch -regex ($item.TrimStart().Substring(0,3))
        {
            "CN=" {$CN = '/' + $item.replace("CN=","");continue}
            "OU=" {$ou += ,$item.replace("OU=","");$ou += '/';continue}
            "DC=" {$DC += $item.replace("DC=","");$DC += '.';continue}
        }
    } 
    $canoincal = $dc.Substring(0,$dc.length - 1)
    for ($i = $ou.count;$i -ge 0;$i -- ){$canoincal += $ou[$i]}
    $canoincal += $cn.ToString().replace('~',',')
    return $canoincal
}

function ConvertFrom-Canonical 
{
param([string]$canoincal=(trow '$Canonical is required!'))
    $obj = $canoincal.Replace(',','\,').Split('/')
    [string]$DN = "CN=" + $obj[$obj.count - 1]
    for ($i = $obj.count - 2;$i -ge 1;$i--){$DN += ",OU=" + $obj[$i]}
    $obj[0].split(".") | ForEach-Object { $DN += ",DC=" + $_}
    return $dn
}

function Convert-LastLogonTimeStamp 
{
param([long]$stamp=(trow '$stamp is required!'))
    if ($stamp -eq 0) {
        $retval = $null
    } else {
        $retval = [DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('MM/dd/yyyy hh:mm:ss')
    }

    return $retval
}

# Gets time stamps for all User in the domain that have NOT logged in since after specified date 
import-module activedirectory  
$time = (Get-Date).Adddays(-($DaysInactive)) 
$excludegroup = Get-ADGroup $GroupExclude

if (-not $Credential) {
    $Credential = Get-Credential
}

if (-not $Server) {
    $DOmainObj = Get-ADDomain -Current "LocalComputer"
    $Server = $DOmainObj.InfrastructureMaster
}
   
# Get all AD User with lastLogonTimestamp less than our time and set to enable 
$inactive = Get-ADUser -Filter {-not (memberOf -RecursiveMatch $excludegroup.DistinguishedName) -and (LastLogonTimeStamp -lt $time) -and (enabled -eq $true)} -Server $Server -Credential $Credential -Properties whenCreated,lastlogonTimeStamp, Department,DistinguishedName,Enabled 

# Get all AD Users who have never logged in
$never = get-aduser -f {-not ( lastlogontimestamp -like "*") -and (enabled -eq $true) -and (whenCreated -lt $time)} -Server $Server -Credential $Credential -Properties whenCreated,lastlogonTimeStamp, Department,DistinguishedName,Enabled

#Sort collection by samAccountName
$UserFormatted = ($inactive + $never) | sort-object SamAccountName | select-object SamAccountName,Name,@{Name="whenCreated"; Expression={$_.whenCreated.ToString("MM/dd/yyyy hh:mm:ss")}}, @{Name="LastLogon"; Expression={Convert-LastLogonTimeStamp($_.lastLogonTimeStamp)}},@{Name="OU"; Expression={ConvertFrom-DN($_.DistinguishedName)}},Department,Enabled

if ($OutputFile) {
    # Output Name and lastLogonTimestamp into CSV  
    $UserFormatted | export-csv $OutputFile -notypeinformation
}

#Write Users into the pipeline
$UserFormatted | Write-Output


#ft -Property Name,samAccountName,Department,OU,whenCreated,LastLogon,Enabled



