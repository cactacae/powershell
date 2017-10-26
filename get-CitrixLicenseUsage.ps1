# Get-CitrixLicensing
Param($LicenseServer)
$licensePool = Invoke-Command -ComputerName $LicenseServer -ScriptBlock {get-ciminstance -class "Citrix_GT_License_Pool" -Namespace "ROOT\CitrixLicensing"}
$licensePool | Select-Object @{n="Product";e={$_.PLD}},
                            @{n="Model";e={"Server"}},  
                            @{n="Type";e={$_.LicenseType}},
                            @{n="Installed";e={$_.Count}},
                            @{n="In Use";e={$_.InUseCount}},
                            @{n="Available";e={$_.PooledAvailable}},
                            @{n="% in use";e={($_.InUseCount/$_.Count)*100}}
