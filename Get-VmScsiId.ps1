<# 
.Acknowledgment
    vNugglets http://www.vnugglets.com/2013/12/get-vm-disks-and-rdms-via-powercli.html
		
	.Example
    Get-VmHardDiskScsiId -vmName <vm>
	
	. Notes
	I have removed code that collects multiple vms
#>

# Set variables
[CmdletBinding()]
param (
[string]$vm = " "
)

## Use get-view to collect the VM object(s)
$VmView = Get-View -Viewtype VirtualMachine -Property Name, Config.Hardware.Device, Runtime.Host -Filter @{"Name" = "$vm"}  
if (($VmView | Measure-Object).Count -eq 0) {Write-Warning "No VirtualMachine objects found matching name pattern '$vm'"; exit}  
  
$arrPropertiesToSelect = "VMName,HardDiskName,ScsiId,SizeGB,RawDeviceId,Path".Split(",")  
 
&{$VmView | %{  
        $viewVmDisk = $_  
        ## get the view of the host on which the VM currently resides  
        $VmView = Get-View -Id  $viewVmDisk.Runtime.Host -Property Config.StorageDevice.ScsiLun  
  
        $viewVmDisk.Config.Hardware.Device | ?{$_ -is [VMware.Vim.VirtualDisk]} | %{  
            $HardDisk = $_  
            $ScsiLun = $VmView.Config.StorageDevice.ScsiLun | ?{$_.UUID -eq $HardDisk.Backing.LunUuid}  
            
            ## the properties to return in new object  
            $VmProperties = @{  
                VMName = $viewVmDisk.Name  
                HardDiskName = $HardDisk.DeviceInfo.Label  
                ## get device's SCSI controller and Unit numbers (1:0, 1:3, etc)  
                ScsiId = &{$strScsiDevice = $_.ControllerKey.ToString(); "{0}`:{1}" -f $strScsiDevice[$strScsiDevice.Length - 1], $_.Unitnumber}  
                #DeviceDisplayName = $oScsiLun.DisplayName  
                SizeGB = [Math]::Round($_.CapacityInKB / 1MB, 0)  
                RawDeviceId = $ScsiLun.CanonicalName  
                Path = $HardDisk.Backing.Filename  
            }  
            New-Object -Type PSObject -Property $VmProperties
        }  
}} | Select $arrPropertiesToSelect | ft -a 

	
