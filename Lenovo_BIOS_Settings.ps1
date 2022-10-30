<#
.SYNOPSIS
Get BIOS Settings for Lenovo devices, based on custom definitions in script

.EXAMPLE
.\Lenovo_BIOS_Settings_Remediate.ps1

.DESCRIPTION
Remediate custom BIOS settings for Lenovo devices

.NOTES
   Version:		0.1
   Creation Date:	12-10-2022
   Author:		Ákos Bakos
   Company:		SmartCon GmbH
   Contact:		akos.bakos@smartcon.ch

   Copyright (c) 2022 SmartCon GmbH

HISTORY:
Date			By			Comments
----------		---			----------------------------------------------------------

#>

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Set_Lenovo_BIOS_Settings.log"
Start-Transcript -Path (Join-Path "C:\OSDCloud\Logs\" $Global:Transcript) -ErrorAction Ignore

If(!(Test-Path $Log_File)){New-Item $Log_File -Type file -Force}
Function Write-Log
	{
	param(
	$Message_Type, 
	$Message
	)
		$MyDate = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
		Add-Content $Log_File  "$MyDate - $Message_Type : $Message"
		Write-Host  "$MyDate - $Message_Type : $Message"
	} 

	# Get manufacturer 
$Get_Manufacturer_Info = (Get-WmiObject win32_computersystem).Manufacturer
If($Get_Manufacturer_Info -notlike "*lenovo*")	
	{
		Write-Log -Message_Type "ERROR" -Message "Device manufacturer not supported"											
		Write-Output "Device manufacturer not supported"
		EXIT 1			
	}
Else	
	{
		Write-Log -Message_Type "INFO" -Message "Device manufacturer is Lenovo"											
	}

Write-Log -Message_Type "INFO" -Message "Staring the script"

# Define custom settings
$Get_Settings = @(
[pscustomobject]@{
    Setting = 'BootOrder'
    Value = 'NVMe0:USBHDD'
    }

[pscustomobject]@{
    Setting = 'BootOrderLock'
    Value = 'Enable'
    }
	
[pscustomobject]@{
	Setting = 'UserPresenceSensing'
	Value = 'Disable'
	}

[pscustomobject]@{
	Setting = 'BIOSUpdateByEndUsers'
	Value = 'Enable'
	}

[pscustomobject]@{
	Setting = 'WindowsUEFIFirmwareUpdate'
	Value = 'Enable'
	}
)	
# Change BIOS settings
$BIOS = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi 
ForEach($Settings in $Get_Settings)
    {
        $MySetting = $Settings.Setting
        $NewValue = $Settings.Value				
        Write-Log -Message_Type "INFO" -Message "Change to do: $MySetting - $NewValue"  
        $Change_Return_Code = $BIOS.SetBiosSetting("$MySetting,$NewValue").Return

        If(($Change_Return_Code) -eq "Success")        								
            {
                Write-Log -Message_Type "INFO" -Message "New value for $MySetting is $NewValue"  	
                Write-Log -Message_Type "SUCCESS" -Message "The setting has been set"  												
            }
        Else
            {
                Write-Log -Message_Type "ERROR" -Message "Can not change setting $MySetting (Return code $Change_Return_Code)"  											
            }								
    }

# Save BIOS change part
$Save_BIOS = (Get-WmiObject -class Lenovo_SaveBiosSettings -namespace root\wmi)
$Save_Change_Return_Code = $SAVE_BIOS.SaveBiosSettings().Return		
If(($Save_Change_Return_Code) -eq "Success")
	{
		Write-Log -Message_Type "SUCCESS" -Message "BIOS settings have been saved"
		Add-Content $Log_File ""																
	}
Else
	{
		Write-Log -Message_Type "ERROR" -Message "An issue occured while saving changes - $Save_Change_Return_Code"
		Add-Content $Log_File ""																		
	}