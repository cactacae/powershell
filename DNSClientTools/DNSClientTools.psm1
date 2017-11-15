# accepts one or more host names on the pipeline and resolves them to one or more IP aaddresses
# If the host name cannot be resolved "Unknown IP" is returned
# 

function Find-IP {
	[CmdletBinding()]
	param (
		[alias("ComputerName","HostName")]
		[parameter(Position=0,
			Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)]
			[string]$DNSHostName
	)

	Begin {
#		$results = @()
	}

	Process {
		try {
			$ComputerName = $DNSHostName[0]
			$ip = [System.Net.Dns]::GetHostEntry($ComputerName)
			#$ip = $ip.IPAddressToString
			write-output ([pscustomobject]@{ComputerName=$ip.HostName; IPAddress=$ip.AddressList})

		} catch {
			write-output ([pscustomobject]@{ComputerName=$ComputerName; IPAddress="Unknown IP"})
		}
	}

	End {
#		write-output $results
	}
}

# accepts one or more IP addresses on the pipeline and resolves them to one or more host names
# If the IP address cannot be resolved "Unresolved" is returned
# 

function Find-HostName {
	[CmdletBinding()]
	param (
		[alias("ComputerName","HostName")]
		[parameter(Position=0,
			Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)]
			[string]$IPAddress
	)

	Begin {
#		$results = @()
	}

	Process {
		try {
			$IP = $IPAddress[0]
			$ComputerName = [System.Net.Dns]::GetHostEntry($IP)
			#$ip = $ip.IPAddressToString
			Write-Output ([pscustomobject]@{ComputerName=$ComputerName.HostName; IPAddress=$IP})

		} catch {
			Write-Output ([pscustomobject]@{ComputerName="Unresolved"; IPAddress=$IP})
		}
	}

	End {
#		write-output $results
	}
}

Export-ModuleMember -Function Find-IP
Export-ModuleMember -Function Find-HostName
