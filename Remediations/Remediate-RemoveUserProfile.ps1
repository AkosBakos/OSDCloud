<#
.SYNOPSIS
Detects if defaultuser0 profile exists

.NOTES
   Version:			0.1
   Creation Date:	07-05-2023
   Author:			Akos Bakos
   Company:			SmartCon GmbH
   Contact:			akos.bakos@smartcon.ch

   Copyright (c) 2023 SmartCon GmbH

HISTORY:
Date			By			    Comments
----------		---			    ----------------------------------------------------------
07-05-2024		Akos Bakos		Initial version
17-05-2024		Akos Bakos		Added local user account detection

#>
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Detect-RemoveUserProfile.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\" $Global:Transcript) -ErrorAction Ignore | Out-Null

Try {
    $ProfileFound = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.LocalPath -eq 'C:\Users\defaultuser0' }
    $UserFound = Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.Name -eq 'defaultuser0' }
    If ($ProfileFound -or $UserFound) {
        Write-Host "defaultuser0 profile/user is found"
        Stop-Transcript | Out-Null

        Exit 1
    }
    Else {
        Write-Host "defaultuser0 profile/user is not found"
        Stop-Transcript | Out-Null

        Exit 0
    }
}

Catch {
    $ErrorMsg = $_.Exception.Message
    Write-Host "Error $ErrorMsg"
    Stop-Transcript | Out-Null

    Exit 1
}
