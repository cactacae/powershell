# script to change DNS Server settings for adapters that contain a specified DNS IP.
# Can be used as a "search and replace"
#
# Example:
# ./Change-DNSClientServerAddress.ps1 "10.10.10.20" "10.10.20.20"
# Would find all adapters configured with a DNS IP of 10.10.10.20 and replace the DNS Servers to 10.10.10.20 with 10.10.20.20
#
# To run the command remotely
# invoke-command btmgmt9 -ScriptPath .\Change-DNSClientServerAddress.ps1  -ArgumentList "10.10.20.10","10.10.20.20"

param(
	[string]$FromIP = (Read-Host "Old IP"),
	[string]$ToIP = (Read-Host "New IP")
)

<# 
Example Output from netsh interface ip show dns

Configuration for interface "Ethernet"
Statically Configured DNS Servers:    10.10.10.10
									  10.10.10.10
Register with which suffix:           Primary only

Configuration for interface "VMware Network Adapter VMnet1"
Statically Configured DNS Servers:    None
Register with which suffix:           Primary only

Configuration for interface "VMware Network Adapter VMnet8"
Statically Configured DNS Servers:    None
Register with which suffix:           Primary only

Configuration for interface "Loopback Pseudo-Interface 1"
Statically Configured DNS Servers:    None
Register with which suffix:           Primary only
#>

function NetSH-GetDNS() {
	$Adapter = $null
	$Adapters = @()
	$netsh = invoke-command {netsh interface ip show dns}
	foreach ($fullline in $netsh) {
		#write-host $line
		if ($fullline.length) {
			$line = $fullline.trimstart().TrimEnd()
			$Coloc = $line.indexof(":")
			if ($Coloc -ne -1) {
				$Field = $line.substring(0,$coloc-1).TrimStart().TrimEnd()
				$Value = $line.substring($coloc+1).TrimStart().TrimEnd()
			}
			switch ($line.SubString(0,5)) {
				"Confi" {
					if ($Adapter -ne $null) {$Adapters += $Adapter}
					$Adapter = ([pscustomobject]@{InterfaceIndex=0;InterfaceAlias=$line.substring(29,$line.length-30); ServerAddresses = @()})
				}
				"Stati" {
					if ($Value -ne "None") {$Adapter.ServerAddresses += $Value}
				}
				"Regis" {
				}
				Default {
					$Adapter.ServerAddresses += $line
				}
			}
		}
	}
	if ($Adapter -ne $null) {$Adapters += $Adapter}
	$Adapters

}


# netsh interface ip show dns
# netsh interface ip set dns "Ethernet" static 10.10.10.20
# netsh interface ip add dns "Ethernet" 10.10.20.20 index=2

function NetSH-SetDNS($Update) {
	if ($Update.NewServerAddresses.length -ne 0) {
		$results = (netsh interface ip set dns $Update.InterfaceAlias static $Update.NewServerAddresses[0])
	}
	if ($Update.NewServerAddresses.length -gt 1) {
		for ($idx=1; $idx -lt $Update.NewServerAddresses.length; $idx++) {
			$results = (netsh interface ip add dns $Update.InterfaceAlias $Update.NewServerAddresses[$idx] index=($idx+1))
		}
	}
}

$Updates = NetSH-GetDNS 

if ($FromIP -ne "") {
#	$Adapters = get-dnsclientserveraddress | where-object({$_.ServerAddresses -contains $FromIP}) 
	$Adapters = NetSH-GetDNS | where-object({$_.ServerAddresses -contains $FromIP}) 

	ForEach ($Adapter in $Adapters) {
		$NewAdds = $Adapter.ServerAddresses.Clone()
		$Update = ([pscustomobject]@{InterfaceIndex=$Adapter.InterfaceIndex; InterfaceAlias=$Adapter.InterfaceAlias; OldServerAddresses = $Adapter.ServerAddresses; NewServerAddresses= $NewAdds})
		$Update.NewServerAddresses[$Update.OldServerAddresses.IndexOf($FromIP)] = $ToIP
		NetSH-SetDNS $Update
		# set-dnsclientserveraddress -InterfaceIndex $Adapter.InterfaceIndex -ServerAddresses $Update.NewServerAddresses
		$Update 
	}
}


