function Find-IP {
	[CmdletBinding()]
	param (
		[alias("ComputerName")]
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
