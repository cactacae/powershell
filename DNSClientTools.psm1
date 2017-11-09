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
			[string[]]$DNSHostName
	)

	Begin {
		$results = @()
	}

	Process {
		try {
			$ComputerName = $DNSHostName[0]
			$ip = [System.Net.Dns]::GetHostAddresses($ComputerName)
			#$ip = $ip.IPAddressToString
			$results += [pscustomobject]@{ComputerName=$ComputerName; IPAddress=$ip.IPAddressToString}

		} catch {
			$results += [pscustomobject]@{ComputerName=$ComputerName; IPAddress="Unknown IP"}
		}
	}

	End {
		write-output $results
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
			[string[]]$IPAddress
	)

	Begin {
		$results = @()
	}

	Process {
		try {
			$IP = $IPAddress[0]
			$ComputerName = [System.Net.Dns]::GetHostEntry($IP)
			#$ip = $ip.IPAddressToString
			$results += [pscustomobject]@{ComputerName=$ComputerName.HostName; IPAddress=$IP}

		} catch {
			$results += [pscustomobject]@{ComputerName="Unresolved"; IPAddress=$IP}
		}
	}

	End {
		write-output $results
	}
}

