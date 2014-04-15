$serverlist = (get-content hosts.txt)

$serverlist | foreach-object {
$server = $_
try {
	$ip = [System.Net.Dns]::GetHostAddresses($_)
	"$server, $ip"

} catch {
	"$server, Unknown IP"
}
}
