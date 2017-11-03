# Create-PVSVM.ps1
# Will read a parameter file and create a sequence of VMs and PVS Device Targets in the configured Datastore and device collection
# Must have PowerCLI and PVS Powershell snap-ins installed
#
# Parameter contains the following settings
# DeviceName=pvsvm####
# Start=1
# Count=100
#
# vCenter=vcenter.domain.local
# vmHost=esx10.domain.local
# dvSwitch=vSwitch1
# PortGroup=Citrix
# Datastore=SANStore1
#
# PVSServer=pvs1.domain.local
# PVSUser=wpvsadmin
# PVSDomain=domain.local
# PVSImageName=PVS-VM
# PVSCollection=PVS-VMs
# ISOPath=SANIso\pvsboot.iso

param(
	[string]$configFile = ".\Create-PVSVM.txt"
)

asnp vmware.*
asnp mcli*

$pdata = (Get-Content $configFile | ConvertFrom-StringData)

$pvshostname = $pdata.PVSServer
$pvsuser = $pdata.PVSUser
$pvsdomain = $pdata.PVSDomain
$pvsimagename = $pdata.PVSImageName
$PVSCollectionName = $pdata.PVSCollection

if ($pvsuser) {
    $pvspassword = read-host "Enter PVS User Password"
}

mcli-run setupConnection -p server=$pvshostname,user=$pvsuser,domain=$pvsdomain,password=$pvspassword
$StoreRecord=mcli-get store -f StoreID

$SiteRecord=mcli-get store -f SiteID

$StoreID = foreach ($a in $StoreRecord) { if ($a -match ‘-’) {$a.Replace(‘storeId: ‘,'')}}

$SiteID = foreach ($b in $SiteRecord) { if ($b -match ‘-’) {$b.Replace(‘siteId: ‘,'')}}

#init ESX Connection
$vcenterhostname = $pdata.vCenter
$vmhostname = $pData.vmHost
$vmname = $pdata.DeviceName
$dvswitchname = $pdata.dvSwitch
$pgname = $pdata.PortGroup
$dsname = $pdata.Datastore
$isoPath = $pdata.ISOPath

Connect-VIServer $vcenterhostname

$vmhost = (Get-VMHost $vmhostname)

#get vds portgroup to attach
$pg = Get-VirtualPortGroup -VirtualSwitch $dvswitchname -name $pgname
# $rp = get-resourcepool "RP?"

#get datastore for vm disk
$ds = (Get-Datastore $dsname)

$NumLength = [regex]::matches($pdata.DeviceName,"#").count
$sNumFmt = "{0:D" + $numLength + "}"
$sNumTplt = "#" * $NumLength

for ($iNum = [int]$pdata.Start; $iNum -lt $iNum+[int]$pdata.count; $iNum++) {
	#get zero padded, length appropriate number
	$sNum = $sNumFmt -f $iNum

	#build vmname with number
	$vmname = $pdata.DeviceName -replace $sNumTplt,$sNum

	$vm = (new-vm -name $vmname -VMHost $vmhost -datastore $ds -DiskGB 5 -DiskStorageFormat Thin -Portgroup $pg -NumCpu 4 -MemoryGB 8 -GuestId windows7Server64Guest -Version v8)

	$cd = New-CDDrive -VM $VM -ISOPath $isoPath

	$vnics = Get-NetworkAdapter -VM $vm
	$vnic = $vnics[0]

	Set-Networkadapter -NetworkAdapter $vnic -Type Vmxnet3 -confirm:$false

	Start-VM $vm
	start-sleep -s 5
	Stop-VM -VM $VM  -confirm:$false

	$vnics = Get-NetworkAdapter -VM $vm
	$vnic = $vnics[0]

	Write-host $vmname, $vnic.MacAddress

	get-advancedsetting -Entity $vm -name "scsi0.pciSlotNumber" | set-advancedsetting 192  -confirm:$false
	get-advancedsetting -Entity $vm -name "ethernet0.pciSlotNumber" | set-advancedsetting 160  -confirm:$false


	$mac = $vnic.MacAddress.tostring().replace(":","-")

	Mcli-add device -r deviceName=$vmname,deviceMac=$mac, collectionName=$PVSCollectionName, siteid=$SiteID
	mcli-run AssignDiskLocator -p DeviceName=$vmname,DiskLocatorName=$PVSImageName,siteid=$SiteID,storeid=$StoreID
}