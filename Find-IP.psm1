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

#lookup-ip $input
