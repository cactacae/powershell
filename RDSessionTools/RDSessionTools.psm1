function Get-RDSession {
    [CmdletBinding()]
    param (
        [alias("ComputerName","HostName")]
        [parameter(Position=0,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="ComputerName")]
            [string[]]$DNSHostName,

        [parameter(Position=0,
            Mandatory=$false,
            ValueFromPipeline=$true,
            ParameterSetName="PSSession")]
            [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    )

    Begin {
#        $SessionList = @()
    }

    Process {
        Switch ($PSCmdlet.ParameterSetName)
            {
                "ComputerName" {
                    if ($DNSHostName -eq $null) {
                        $queryResults = (quser 2>$null)
                    } else {
                        # Run quser and parse the output 
                        $queryResults = (quser /server:$DNSHostName 2>$null)
                    }
                }
                "PSSession" {
                    $queryresults = (Invoke-command -Session $PSSession -ScriptBlock {quser 2>$null})
                    $DNSHostName = $PSSession.ComputerName
                }
            }

            if ($queryresults) {
                #$sessionList += (ConvertTo-RDSession $queryResults $DNSHostName)
                ConvertTo-RDSession $queryResults $DNSHostName
            }
    }

    End {
        #write-output $SessionList
    }  
}

class RDSession {
	[string]$SessionName
	[string]$Username
	[int]$ID
	[string]$State
	[TimeSpan]$IdleTime
	[datetime]$LogonTime
	[string]$ComputerName 
}

#Function to convert from RD Idle Time (DD+HH:mm) format into PS TimeSpan type
function ConvertTo-TimeSpan {
    param (
        [string]$RDIdleSpan
    )
    #Non Idle sessions report . instead of 0.  Change to 0 if idle.
    $RDIdleSpan= $RDIdleSpan.replace(".","0")
    if ($RDIdleSpan -eq "None") {$RDIdleSpan = 0}

	$IdleDays = 0
	$IdlePlus = $RDIdleSpan.indexof("+")
	if ($IdlePlus -ne -1) {
		$IdleDays = $RDIdleSpan.substring(0,$IdlePlus)
		$RDIdleSpan = $RDIdleSpan.substring($idleplus+1)
	}
	$IdleHours = 0
	$IdleColon = $RDIdleSpan.indexof(":")
	if ($IdleColon -ne -1) {
		$IdleHours = $RDIdleSpan.substring(0,$IdleColon)
		$RDIdleSpan = $RDIdleSpan.substring($IdleColon+1)
	}
	$IdleMinutes = $RDIdleSpan

    write-output (New-Timespan -Days $IdleDays -Hours $IdleHours -Minutes $IdleMinutes)

}

function ConvertTo-RDSession {
    param(
        [string[]]$quser,
        [string]$computername
    )

#	$SessionList = @()

    #Check for no RD Sessions
    if ($quser.Length) {

        # Pull the session information from each instance 
        ForEach ($Line in $quser) { 
            $SESSIONNAME = $Line.SubString(23,16).trim()
            if ($SESSIONNAME -ne "SESSIONNAME") {
                $USERNAME = $Line.SubString(1,20).trim()
                $ID = $Line.SubString(40,5).trim()
                $STATE = $Line.SubString(46,8).trim()
                $IDLE_TIME = $Line.SubString(54,9).trim()
                $LOGON_TIME = $Line.SubString(65).trim()


                $Session = [RDSession]::new()
    #			$Session = new-object psobject
                $Session.SessionName = $SESSIONNAME
                $Session.Username = $USERNAME
                $Session.ID = $ID
                $Session.State = $STATE
                $Session.IdleTime = (ConvertTo-TimeSpan $IDLE_TIME)
                $Session.LogonTime = ([system.datetime]($LOGON_TIME))
                $Session.ComputerName = $computername
            
#                $SessionList += $Session
                Write-Output $Session
            }
        }
    }
##############################
#.SYNOPSIS
#Short description
#
#.DESCRIPTION
#Long description
#
#.PARAMETER quser
#Parameter description
#
#.PARAMETER computername
#Parameter description
#
#.EXAMPLE
#An example
#
#.NOTES
#General notes
##############################   write-output $SessionList
}

Function Remove-RDSession {
    [CmdletBinding()]
    param (
        [parameter(Position=0,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="RDSession")]
        [string[]]$ComputerName,
        [alias("ID")]
        [parameter(Position=1,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="RDSession")]
        [int32[]]$SessionID
    )
            
    #     [parameter(Position=0,
    #         Mandatory=$false,
    #         ValueFromPipeline=$true,
    #         ParameterSetName="PSSession")]
    #         [System.Management.Automation.Runspaces.PSSession[]]$PSSession
    
    Process {
        Switch ($PSCmdlet.ParameterSetName) {
            "RDSession" {
                if ($computerName -ne $null) {
                    $logoffcmd = {logoff.exe $SessionID /server:$ComputerName}
                    invoke-command -ScriptBlock $logoffcmd 
                }
            }
        }
    }
    
}

Export-ModuleMember -Function Get-RDSession
Export-ModuleMember -Function Remove-RDSession