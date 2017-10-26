#script to change DNS Server settings for adapters that contain a specified DNS IP.
#Can be used as a "search and replace"
#Example:
# ./Change-DNSServers.ps1 "10.10.10.20" @("10.10.10.20","10.10.20.20")
# Would find all adapters configured with a DNS IP of 10.10.10.20 and set the DNS Servers to 10.10.10.20 and 10.10.20.20
# To run the command remotely
#invoke-command .\change-dnsservers.ps1 btmgmt9 -ArgumentList "10.10.20",@("10.10.10.20","10.10.20.20")

param(
	[string]$FromIP,
	[string[]]$ToIPs
)

if ($FromIP -ne "") {
	$Adapters = get-dnsclientserveraddress | where-object({$_.ServerAddresses -contains $FromIP}) 

	write-output $adapters

	if ($ToIPs -ne "") {
		$adapters |foreach-object({set-dnsclientserveraddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses $ToIPs})
	}
}
